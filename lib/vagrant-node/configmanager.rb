require 'vagrant'
require 'ruby_parser'
require 'ruby2ruby'
require 'vagrant-node/exceptions.rb'


module VagrantPlugins
  module Kernel_V2
    class VMConfig < Vagrant.plugin("2", :config)
      def networks
        used_ifaces = []
        @__networks.each do |key,value|
          type = value[0]
          netinfo = value[1]
          if (type!=:forwarded_port)
            iface = nil
            iface = netinfo[:bridge] if netinfo.has_key? :bridge
            if (iface && !used_ifaces.include?(iface))
              used_ifaces << iface
            else
              @__networks.delete(key)
            end
          end
        end

        @__networks.values
      end


    end

  end
end


module Vagrant
  module Node
    class ConfigManager
      attr_accessor :config_global,:config_warnings,:config_errors,:config_sexp
      def initialize(spath_config_file)

        @config_file_path = spath_config_file
        config_loader = Config::Loader.new(Config::VERSIONS, Config::VERSIONS_ORDER)
        config_loader.set(:conffile, File.expand_path(@config_file_path))
        @config_global,@config_warnings, @config_errors = config_loader.load([:confile])
        pp @config_global
        config_content = File.read(@config_file_path)

        @config_sexp = RubyParser.new.parse(config_content)

        #If config file is in the default style convert it to a block one
        convert_default_to_block

      end


      def extract_vms_sexp


        index=VM_INDEX_START

        if (@config_sexp[0]==:iter)
          block=@config_sexp
        else

          gindex=0
          block=nil
          @config_sexp.each_sexp do |conf|
             gindex=gindex+1
             if (conf.node_type == :iter)
               block = @config_sexp[gindex]
             end
          end

        end




        raise RestException.new(406,
                               "Config File has no virtual machine configured") if (block.nil? ||
                                                                                    block.empty? ||
                                                                                    block[index].nil?)




        if block[index].node_type==:block

            if (block[index].find_nodes(:iter).empty?)
              #One machine with default style
              return default_to_block

            else
              #Several machines configured
              return block[index].find_nodes(:iter)
            end

        else

            return [block[index]]
        end

      end

      def delete_vm (vm_name)
        index=get_start_index





        if (@config_sexp[0]==:iter)
          nodo=@config_sexp
        else
          nodo=@config_sexp.find_nodes(:iter).first
        end


        if (!nodo[VM_INDEX_START].nil?)

          if (nodo[VM_INDEX_START].node_type == :iter)
            vm = nodo[VM_INDEX_START].find_nodes(:call)

            if (!vm.empty?)
              leaf= vm.first.find_nodes(:lit)

              if (!leaf.empty? && leaf.first.value === vm_name.to_sym)
                nodo.delete_at(VM_INDEX_START)

                save
                return true
              end
            end
          elsif (nodo[VM_INDEX_START].node_type == :block)
             nodo[VM_INDEX_START].each_sexp do |vm|


                subnode=vm.find_nodes(:call)
                if (!subnode.empty?)
                  leaf=subnode.first.find_nodes(:lit)
                  if (!leaf.empty? && leaf.first.value === vm_name.to_sym)

                    nodo[VM_INDEX_START].delete(vm)
                    save

                    return true
                  end
                end

             end
          end


        end



        raise RestException.new(404,"Virtual Machine #{vm_name} not found")


      end


      def get_vm_extract(vmname)

        index=get_start_index
        raise RestException.new(406,"No virtual machine configured") if @config_sexp[index].nil?

        machines = extract_vms_sexp

        entry = nil

        machines.each do |machine|
          machine.find_nodes(:call).first.find_nodes(:lit).each do |node|
            if node.value==vmname.to_sym
              entry=machine
              break;
            end
          end
          break if !entry.nil?
        end

        entry

      end

      def set_global_variables(variables)

        # pp @config_sexp

        #FIXME NO ESTÁ TERMINADO, NO SE INCLUYE CORRECTAMENTE
        #AL BLOQUE AL FINAL

        @config_sexp.find_nodes(:gasgn).each do |var|
            @config_sexp.delete(var)
        end


        aux=s(:block)
        variables.each do |key,value|
          if value.include? "\n"
            aux.add(RubyParser.new.parse("#{key}=<<SCRIPT\n#{value}\nSCRIPT"))
          else
            aux.add(RubyParser.new.parse("#{key}=#{value}"))
          end
        end

        # pp @config_sexp.size

        for i in 1..(@config_sexp.size-1)
          aux.add(@config_sexp[i])
        end


      end


      def set_providers(vmname,providers,variables)

        machine = get_vm_extract vmname

        set_global_variables variables

        # pp @config_sexp




      end


      def get_providers(vmname)

        machine = get_vm_extract vmname



        response_block = []
        #Primero obtenemos los bloques de tipo iter para comprobar si son de configuración
        #Este caso es para cuando hay un bloque de tipo provision dentro de una máquina virtual
        #
        #config.vm.define(:centos5) do |centos5_config|
        #  centos5_config.vm.provision :chef_solo do |chef|
        #  ....
        #  end
        #end
        #Buscando bloques iter
        iter_blocks = machine[VM_INDEX_START].find_nodes(:iter)
        iter_blocks.each do |block|


          mblock=block.find_nodes(:call)

          if (!mblock.first.nil? &&
             !mblock.first.empty? &&
             !mblock.first[2].nil? &&
             !mblock.first[2].empty? &&
             mblock.first[2] == :provision &&
             #Si el bloque tiene el index 3 implica que tiene
             #contenido y por tanto lo analizamos. Si no tiene
             #ese indice lo obviamos al estar vacio
             !block[3].nil?)


             provisioner = mblock.first[3].value

             #En block[3] se encuentran los argumentos del bloque de provisioning
             #Pero hay un problema, si las asignaciones de tipo a = b el bloque tiene otra
             #estructura y, de hecho, el = se añade al final del nombre (ej: :add_recipe=)
             #En cambio, si no tiene igual y se hace de tipo add_recipe 'zip' el nombre
             #será el correcto, pero la estructura es diferente

             #FIXME SI FUERA NECESARIO TENER EN CUENTA EL ORDEN EN EL QUE ESTÁN LAS DIRECTIVAS
             #EN LA CONFIGURACIÓN, HABRIA QUE RECORRER EL SEXP Y ANALIZAR CADA ENTRADA
             #EN VEZ DE HACERLO COMO AHORA, QUE PROCESA LA INFORMACIÓN POR SEPARADO

             aux = extract_provision_attributes_formal_form(block[3]) + extract_provision_attributes(block[3])

             response_block << { provisioner => aux } if aux.size > 0

          end
        end




        #Despues obtenemos los bloques de tipo call para comprobar si son de configuración
        #Este caso es para cuando hay un bloque de tipo provision sin bloque
        #
        #centos5_config.vm.provision :shell, inline: "echo Hello World"

        call_blocks = machine[VM_INDEX_START].find_nodes(:call)
        call_blocks.each do |block|
          if block[2] == :provision
            provisioner = block[3].value
            aux = extract_provision_hash_attributes(block)
            response_block << { provisioner => aux } if aux.size > 0
          end
        end

        response_block = {:providers => response_block,:global_vars=> get_global_variables }

        response_block

      end


      def get_vm_names

        index=get_start_index
        raise RestException.new(406,"No virtual machine configured") if @config_sexp[index].nil?

        names = []
        if @config_sexp[index].node_type==:block
          #Entorno con una maquina configurada fuera de bloque
          if (@config_sexp[index].find_nodes(:iter).empty?)
            names.push(:default)
          else
          #Entorno multi vm
            @config_sexp[index].each_sexp do |vm|
              vm.find_nodes(:call).first.find_nodes(:lit).each do |node|
                names.push(node.value)
              end
            end
          end

        else
        #Este caso se produce cuando hay unicamente
        #una maquina virtual configurada. En este caso
        #@config_sexp[VM_INDEX_START] contiene la definicion
        #de la maquina directamente
        node=@config_sexp[index].find_nodes(:call).first.find_node(:lit)
        names.push(node.value)

        end

        names
      end


      #FIXME REVISAR PORQUE CUANDO QUEDA UNA ÚNICA máquina en un entorno
      #multi vm el fichero cambia
      def rename_vm(old_name,new_name)

        machines = extract_vms_sexp

        machines.each do |machine|
          machine.find_nodes(:call).first.find_nodes(:lit).each do |node|
            node[1] = new_name.to_sym if (node.value == old_name)
          end
        end

      end

      def insert_vms_sexp(vms_sexp)

        raise RestException.new(406,"Invalid configuration file supplied") if vms_sexp.nil? || vms_sexp.empty?
        index=VM_INDEX_START



        if @config_sexp[0]==:iter
          block=@config_sexp
        else
          gindex=0
          block=nil
          @config_sexp.each_sexp do |conf|
             gindex=gindex+1
             if (!conf.nil? && conf.node_type == :iter)
               block = @config_sexp[gindex]
             end

          end
        end





        if !block[VM_INDEX_START].nil?
          # If @config_sexp[VM_INDEX_START] isn't nil could mean three things:
          #  -- There is a machine configured with a default style
          #  -- There are some machines inserted inside a block
          #  -- There is only one machine and it is stored at block[VM_INDEX_START]
          if block[VM_INDEX_START].node_type==:block
            # If node is a block it could be the first two options
            if (block[VM_INDEX_START].find_nodes(:iter).empty?)
              # This case match the first option, so the steps to perform are the following:
              # -- Create a block node
                new_block = s(:block)
              # -- Convert the current machine to a block style and insert into the block
                new_block.add(default_to_block)
              # -- Insert the new vms
                new_block.add(vms_sexp)


              @config_sexp.delete_at(index)

              @config_sexp[index] = new_block


            else
              # This case means that there are some machines inserted inside a block
              # we only have to add thems
              #FIXME FALTA COMPREOBAR SI HACE FALTA RENOMBRAR
              if @config_sexp[0]==:iter
                @config_sexp[VM_INDEX_START].add(vms_sexp)
              elsif @config_sexp[0]==:block
                 @config_sexp[gindex][VM_INDEX_START].add(vms_sexp)
              end

            end

          else


            #There is only one machine stored, we can store it at @config_sexp[index]
            new_block = s(:block)

            result = extract_vms_sexp


            if (@config_sexp[0]==:block)
              #SI el elemento 0 es un bloque

              new_block.add(result)
              new_block.add(vms_sexp)


              block.delete_at(VM_INDEX_START)
              @config_sexp[gindex][VM_INDEX_START]=new_block

            else
              new_block.add(extract_vms_sexp)
              new_block.add(vms_sexp)
              @config_sexp.delete_at(index)


              @config_sexp[index] = new_block
            end

          end
        else
            #If @config_sexp[VM_INDEX_START] is nil means that there isn't any
            #machine configured
            #In order to proceed correctly we have to check if there are one or more
            #vms to be inserted:
            #  -- If there is only one machine to be inserted is must be stored in
            #  @config_sexp[VM_INDEX_START] directly
            #  -- If there are two ore more vms to be inserted they have to be inserted inside
            #  a block in @config_sexp[VM_INDEX_START]


            if (vms_sexp.length>1)
              new_block = s(:block)
              new_block.add(vms_sexp)
              @config_sexp[index] = new_block
            else
              @config_sexp[index] = vms_sexp.first
            end

        end

        # Saving the result to disk
        save

        true

      end

      #Ruby2Ruby modify the parameter, so a deep cloned copy is passed
      def config_content

        begin
          Ruby2Ruby.new.process(@config_sexp.dclone)
        rescue => e
          raise RestException.new(406,"There was an error processing the config file, check if there is any error")
        end
      end

      def save
        #Processing the content first. If there is any error
        #the file wont'be modified
        content= config_content
        f = File.open(@config_file_path, "w")
        f.write(content)
        f.write("\n")
        f.close
      end

      private
        VM_INDEX_START = 3
        DEFAULT_BLOCK_NAME = :default_config
        DEFAULT_MACHINE = "default"


        def extract_provision_attributes_formal_form(block)

          res = []

          #Este caso se produce cuando sólo hay una directiva
          #dentro del bloque de configuración del provider
          #y es del tipo add_recipe = 'example'

          if (block[0] == :attrasgn)

            if (!block[2].nil? && !block[2].empty? &&
                !block[3].nil? && !block[3].empty? &&
                block[2][-1,1]=="=")

              cad=block[2].to_s
              statement = cad.chop
              statement = statement.to_sym
              value = block[3].value

              res << { statement => value }

            end

          elsif block[0] == :block



            block.find_nodes(:attrasgn).each do |assign|

              statement = nil
              value = nil


              if (!assign[2].nil? && !assign[2].empty?)
                cad=assign[2].to_s
                statement = cad.chop
                statement = statement.to_sym


                if (assign[3].node_type==:array)

                  s = assign[3].size

                  parray=[]
                  for i in 1..(s-1)
                    parray << assign[3][i].value
                  end

                  value = parray
                elsif (assign[3].node_type==:hash)

                  argarray = {}
                  argrecipe=nil

                  assign[3].each do |piece|
                    if (piece == :hash)
                      next
                    end

                    if (piece.node_type==:str)
                      #En este bloque se especifica el nombre de la receta
                      argrecipe=piece.value
                    elsif (piece.node_type==:hash)
                      #En este bloque está el array correspondiente
                      #con los parametros y el valor
                      argname=nil
                      argvalue=nil

                      s = piece.size

                      arguments = {}

                      for i in 1..(s-1)
                        if ((i%2)==1)
                          argname=piece[i].value
                        else
                          argvalue=piece[i].value

                          arguments[argname]=argvalue

                          # arguments << {argname => argvalue }

                        end

                      end

                      argarray[argrecipe]=arguments
                    end

                  end

                  # pp "***************"
                  # pp argarray
                  # pp "***************"
                  value = argarray

                else
                  value = assign[3].value
                end

                res << { statement => value }

              end
            end

          end

          res
        end

        def extract_provision_attributes(block)

          res = []

          #Este caso se produce cuando sólo hay una directiva
          #dentro del bloque de configuración del provider
          #y es del tipo add_recipe 'example'
          if (block[0] == :call)

            if (!block[2].nil? && !block[2].empty? &&
                !block[3].nil? && !block[3].empty? &&
                block[2][-1,1]!="=")

              statement = block[2]
              value = block[3].value

              res << { statement => value }

            end

          elsif block[0] == :block


            block.find_nodes(:call).each do |assign|

              if (!assign[2].nil? && !assign[2].empty?)
                statement = assign[2]
                value = assign[3].value

                # res[statement] = value

                res << { statement => value}
              end
            end

          end

          res
        end



        def extract_provision_hash_attributes(block)

          res = []

          #Este caso se produce cuando sólo hay una directiva
          #dentro del bloque de configuración del provider
          #y es del tipo add_recipe 'example'
          if (block[0] == :call)

            #En block[3].value está el nombre del provider
            if (!block[4][1].nil? && !block[4][1].empty? &&
                !block[4][2].nil? && !block[4][2].empty?)

              statement = block[4][1].value
              value = block[4][2].value



              # params = []

              #TODO comento el procesamiento de las variables dentro de este
              #provider ya que una variable puede usarse en varios providers y script
              # if (!vars.nil? && vars.size>0)
              #   vars.each do |var|
              #     if (var.first[0] == value)
              #       #TODO NO REEMPLAZAR POR EL VALOR
              #       value = var.first[1]
              #     end
              #   end
              # end

              #TODO ver las variables del fichero en caso de que
              #el statement sea :inline y el contenido sea una variable
              #por ejemplo
              #centos5_config.vm.provision :shell, inline: $script

              res << { statement => value }
            end

          end

          res
        end


        def rename_block_to_default(exp)
          exp.each_sexp do |node|
            rename_block_to_default(node)
            if (node.node_type == :lvar)
              node[1]=DEFAULT_BLOCK_NAME
            end
          end
        end

        def get_start_index

          if (@config_sexp[0]==:iter)
            return VM_INDEX_START
          else
            return VM_INDEX_START-1
          end
        end


        def get_global_variables
          vars = []

          @config_sexp.find_nodes(:gasgn).each do |var|
            varname = var[1]
            varvalue = var[2].value
            vars << { varname => varvalue}
          end

          vars
        end

        #Process a default virtual machine and produces
        #a block with the vm configuration
        def default_to_block
            #Getting the main block name
            mblock_name = @config_sexp[2].value.to_s

            rename_block_to_default(@config_sexp[VM_INDEX_START])

            result= RubyParser.new.parse(
                                         "Vagrant.configure('2') do |#{mblock_name}|"+
                                         "config.vm.network :forwarded_port,guest: 22,host: 2222,host_ip: '0.0.0.0',id: 'ssh',auto_correct: true\n"+
                                         "#{mblock_name}.vm.define(:#{DEFAULT_MACHINE}) do |#{DEFAULT_BLOCK_NAME.to_s}|\n"+
                                         Ruby2Ruby.new.process(@config_sexp[VM_INDEX_START].dclone)+
                                         "end\nend"
                                         )



             return [result[VM_INDEX_START]]
        end


        def convert_default_to_block

          if (@config_sexp[0]==:iter)


            #Caso en el que el fichero no tiene ningún contenido, tan solo el config
            if (!@config_sexp[VM_INDEX_START].nil?)
              if (@config_sexp[VM_INDEX_START].node_type==:attrasgn)
                #Caso en el que el fichero es por defecto y los atributos están fuera
                #de un bloque
                new_block = s(:block)
                new_block.add(default_to_block)



                @config_sexp.delete_at(VM_INDEX_START)
                @config_sexp[VM_INDEX_START] = new_block

              elsif (@config_sexp[VM_INDEX_START].node_type==:block &&
                  @config_sexp[VM_INDEX_START].find_nodes(:iter).empty?)

                 new_block = s(:block)
                 new_block.add(default_to_block)

                 @config_sexp.delete_at(VM_INDEX_START)
                 @config_sexp[VM_INDEX_START] = new_block


              end
            end

          else
            #Busco donde comienza la declaración del bloque principal

            gindex=0
            block=nil
            @config_sexp.each_sexp do |conf|
               gindex=gindex+1
               if (conf.node_type == :iter)
                 block = @config_sexp[gindex]
               end

            end



            if (!block.nil?)

              if (block[VM_INDEX_START].nil?)
                mblock_name = block[2][1].to_s
                block= RubyParser.new.parse(
                                           "Vagrant.configure('2') do |#{mblock_name}|"+
                                           "config.vm.network :forwarded_port,guest: 22,host: 2222,host_ip: '0.0.0.0',id: 'ssh',auto_correct: true\n"+
                                           "#{mblock_name}.vm.define(:#{DEFAULT_MACHINE}) do |#{DEFAULT_BLOCK_NAME.to_s}|\n"+
                                           "end\nend"
                                           )

                @config_sexp[gindex] = block

              elsif (!block[VM_INDEX_START].nil? && block[VM_INDEX_START].node_type==:attrasgn)


                mblock_name = block[2][1].to_s


                rename_block_to_default(block[VM_INDEX_START])

                block= RubyParser.new.parse(
                                           "Vagrant.configure('2') do |#{mblock_name}|"+
                                           "config.vm.network :forwarded_port,guest: 22,host: 2222,host_ip: '0.0.0.0',id: 'ssh',auto_correct: true\n"+
                                           "#{mblock_name}.vm.define(:#{DEFAULT_MACHINE}) do |#{DEFAULT_BLOCK_NAME.to_s}|\n"+
                                           Ruby2Ruby.new.process(block[VM_INDEX_START].dclone)+
                                           "end\nend"
                                           )





                @config_sexp[gindex]=block


              elsif (block[VM_INDEX_START].node_type==:block &&
                    block[VM_INDEX_START].find_nodes(:iter).empty?)


                   new_block = s(:block)
                   new_block.add(default_to_block)

                   block.delete_at(VM_INDEX_START)
                   block[VM_INDEX_START] = new_block


              end

            end

          end

        end

    end

  end
end
