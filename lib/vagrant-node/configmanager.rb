require 'vagrant'
require 'ruby_parser'
require 'ruby2ruby'
require 'vagrant-node/exceptions.rb'

module Vagrant
  module Node
    class ConfigManager
      attr_accessor :config_global,:config_warnings,:config_errors,:config_sexp
      def initialize(spath_config_file)
        @config_file_path = spath_config_file
        config_loader = Config::Loader.new(Config::VERSIONS, Config::VERSIONS_ORDER)
        config_loader.set(:conffile, File.expand_path(@config_file_path))
        @config_global,@config_warnings, @config_errors = config_loader.load([:confile])

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

        #Process a default virtual machine and produces
        #a block with the vm configuration
        def default_to_block            
            #Getting the main block name
            mblock_name = @config_sexp[2].value.to_s
                        
            rename_block_to_default(@config_sexp[VM_INDEX_START])
            
            result= RubyParser.new.parse(
                                         "Vagrant.configure('2') do |#{mblock_name}|"+
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
                                           "#{mblock_name}.vm.define(:#{DEFAULT_MACHINE}) do |#{DEFAULT_BLOCK_NAME.to_s}|\n"+                                           
                                           "end\nend"
                                           )  

                @config_sexp[gindex] = block

              elsif (!block[VM_INDEX_START].nil? && block[VM_INDEX_START].node_type==:attrasgn)
                
                
                mblock_name = block[2][1].to_s              
                
                
                rename_block_to_default(block[VM_INDEX_START])

                block= RubyParser.new.parse(
                                           "Vagrant.configure('2') do |#{mblock_name}|"+
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

