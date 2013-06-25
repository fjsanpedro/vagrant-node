
require 'vagrant'
require 'vagrant-node/actions/snapshot'
require 'vagrant-node/dbmanager'
#require 'sambal'

module Vagrant
	module Node
		class ClientController	
			
			################################################################
			#######################  BOX LIST METHOD #######################
			################################################################			
			def self.listboxes
			
				ensure_environment
				
				boxes = @env.boxes.all.sort				
				
				fboxes = Array.new				
				boxes.each do |name, provider|					
					fboxes << {"name" => name,"provider" => provider}
				end
								
				fboxes
				
			end
			
			################################################################
			#######################  BOX DELETE METHOD #####################
			################################################################			
			def self.box_delete(box,provider)
			
				ensure_environment
				
				boxes = []			

			  box = @env.boxes.find(box,provider.to_sym)
			  
			  if (box)			  	
			  	boxes << box.name			  
			  	box.destroy!			  	
			  end 
								
				boxes
				
			end
			
			################################################################
			########################  BOX ADD METHOD #######################
			################################################################			
			def self.box_add(box,url,user="guest",pass="--no-pass")
				
				ensure_environment
				
				boxes = []			

				#TODO
				
				# Get the provider if one was set
				provider = nil
#				provider = options[:provider].to_sym if options[:provider]

				begin
					
					uri = "\\\\155.54.190.227\\boxtmp\\boxes\\debian_squeeze_32.box"
#					
#					if uri=~ /^\\\\(.*?)\\(.*?)\\(.*?)$/						
#						puts "EL HOST ES #{$1}"
#						puts "EL Share ES #{$2}"
#						puts "EL PATH ES #{$3}"
#						host = $1
#						share = $2
#						path = $3
#						
#						Getting and checking box file						
#						boxname=File.basename(path.gsub('\\',File::SEPARATOR))
#						
#            raise 'Box file format not supported' if File.extname(boxname)!=".box"
#
#						samba = nil
#						begin						
#						samba = Sambal::Client.new(  :host     =>  host,
#																				:share    =>  share,
#																				:user     =>  user,
#																				:password =>  pass)
#					
#						
#						
#						Get the tmp file name					
#						temp_path = @env.tmp_path.join("box" + Time.now.to_i.to_s)
#				
#					
#						response = nil
#						
#						smbclient //155.54.190.227/boxtmp --no-pass -W WORKGROUP -U guest -p 445
#						smbclient //155.54.190.227/boxtmp -D boxes -c "get debian_squeeze_321.box" -N
#						
#						command="smbclient //#{host}/#{share} -D #{dirlocation} -c \"get #{boxname}\" -U #{user} --no-pass"
#						
#
#						FIXME encontrar si existe algún tipo de notificación por
#						interrupciónde la descarga
#						FIXME a little hack beacuse in version 0.1.2 of sambal there is 
#						a timeout that close the download after 10 seconds 
#						def samba.ask(cmd)							
#							@i.printf("#{cmd}\n")
#							response = @o.expect(/^smb:.*\\>/)[0]				
#						end
#						
#						response = samba.get(path, temp_path.to_s)
#						FIXME DELETE
#						pp response.inspect						
#						
#						raise response.message if !response.success?
#						
#						if response.success?								
#								File download succesfully
#								added_box = nil
#								begin									
#									provider=nil
#									force = true
#									added_box = @env.boxes.add(temp_path,box,nil,force)									
#									boxes << {:name=>box,:provider=>added_box.provider.to_s}
#								rescue Vagrant::Errors::BoxUpgradeRequired									
#									Upgrade the box
#									env.boxes.upgrade(box)
#			
#									Try adding it again
#									retry
#								rescue Exception => e									
#									boxes = nil
#								end
#													
#						end
#						
#						rescue Exception => e
#							puts "EXCEPCION de descarga" if response
#							puts "EXCEPCION de conexion" if !response
#							puts e.message
#							boxes=nil
#						end
#						
#						
#						Closing connection
#						samba.close if samba
#						
#						
#						Cleaning
#						if temp_path && File.exist?(temp_path)
#            	File.unlink(temp_path)
#          	end
# 
#          	          		 
#					else
#						FIXME Ver qué poner en los parámetros de la llamada
						provider=nil
						force = true # Always overwrite box if exists
						insecure = true #Don't validate SSL certs
						#Calling original box add action
						@env.action_runner.run(Vagrant::Action.action_box_add, {
            :box_name     => box,
            :box_provider => provider,
            :box_url      => url,
            :box_force    => force,
            :box_download_insecure => insecure,
          	})

#					end
					
				rescue =>e
						puts e.message
				end

			  								
				boxes
				
			end
			
			################################################################
			##################  VIRTUAL MACHINE UP METHOD ##################
			################################################################
			def self.vm_up(vmname)
				ensure_environment
			
				machine_names = []
	
				begin
				
					options = {}
					options[:parallel] = true
				
					#Launching machines
					@env.batch(options[:parallel]) do |batch|			
						get_vms(vmname).each do |machine|				
							machine_names << machine.name	
							batch.action(machine, :up, options)					
						end
					end           
					
				
					machine_names
					
				rescue => e						
#					return nil			 
				end
				
			end
		
		  ################################################################
			################  VIRTUAL MACHINE DESTROY METHOD ###############
			################################################################
		
			def self.vm_confirmed_destroy(vmname)
				ensure_environment				
			
				machine_names = []
	
				begin				
				
					get_vms(vmname).each do |machine|				
						machine_names << machine.name
						machine.action(:destroy, :force_confirm_destroy => true)
					end
								
					machine_names
					
				rescue => e					
#					return nil
				end
				
			end
			
			################################################################
			#################  VIRTUAL MACHINE HALT METHOD #################
			################################################################
			def self.vm_halt(vmname,force)
				ensure_environment				
			
				machine_names = []
	
				begin				
				
					get_vms(vmname).each do |machine|
						machine_names << machine.name
						machine.action(:halt, :force_halt => force)
					end
							
					machine_names
				
				rescue => e					
#					return nil
				end
				
			end
			
			################################################################
			#################  VIRTUAL MACHINE STATUS METHOD ###############
			################################################################
			def self.vm_status(vmname)
				ensure_environment				
				
				begin
					
					status = Array.new
										
					get_vms(vmname).each do |machine|
							
						status << {"name" => machine.name.to_s,
									"status" => machine.state.short_description,
									"provider" => machine.provider_name}
					end		
				
				
					status
							
				rescue => e
					puts e.message
#					return nil				
				end
				
			end
			
			################################################################
			##################  VIRTUAL MACHINE SUSPEND METHOD ##################
			################################################################
			def self.vm_suspend(vmname)
				ensure_environment
			
				machine_names = []
			
				begin
				
					
					#Suspendiing machines								
					get_vms(vmname).each do |machine|				
						machine_names << machine.name	
						machine.action(:suspend)
					end           
					
				
					machine_names
					
				rescue => e					
					puts e.message	
#					return nil			 
				end
				
			end
		
			################################################################
			##################  VIRTUAL MACHINE RESUME METHOD ##################
			################################################################
			def self.vm_resume(vmname)
				ensure_environment
			
				machine_names = []
	
				
				begin		
				
					#Launching machines
								
					get_vms(vmname).each do |machine|						
						machine_names << machine.name	
						machine.action(:resume)					
					end
					           
					
				
					machine_names
					
				rescue => e					
					puts e.message	
#					return nil			 
				end
				
			end
			
			################################################################
			############  VIRTUAL MACHINE SNAPSHOT LIST METHOD #############
			################################################################
			def self.vm_snapshots(vmname)
				ensure_environment				
				
				begin
				
					snapshots = {}
										
					get_vms(vmname).each do |machine|
						
						env = 
						{							
        			:machine        => machine,
        			:machine_action => SnapshotAction::LIST
						}
						
						
						res = @env.action_runner.run(SnapshotAction,env)
						
						snapshots[machine.name.to_sym]=res[:snapshots_list]
						
					end		
				
				
					snapshots
							
				rescue => e
					puts e.message
#					return nil				
				end
				
			end
			
			################################################################
			############  VIRTUAL MACHINE SNAPSHOT TAKE METHOD #############
			################################################################
			def self.vm_snapshot_take(vmname,name,desc=" ")
				ensure_environment				
				
				begin
										
					get_vms(vmname).each do |machine|
						env = 
						{							
        			:machine        => machine,
        			:machine_action => SnapshotAction::TAKE,
        			:snapshot_name 	=> name,
        			:snapshot_desc  => desc        			
						}
						
						
						res = @env.action_runner.run(SnapshotAction,env)
						
						return res[:last_snapshot]
						
					end		
							
				rescue => e
					puts e.message
#					return nil				
				end
				
			end
			
			################################################################
			############  VIRTUAL MACHINE SNAPSHOT RESTORE METHOD #############
			################################################################
			def self.vm_snapshot_restore(vmname,snapshot_id)
				ensure_environment				
				
				begin
										
					get_vms(vmname).each do |machine|
						prev_state=machine.state.id
						#First, ensure that the machine is in a proper state
						#to restore the snapshot (save, poweroff)
						machine.action(:suspend) if prev_state==:running
						
						#Now the machine is ready for restoration
						env = 
						{							
        			:machine        => machine,
        			:machine_action => SnapshotAction::RESTORE,
        			:snapshot_id 	=> snapshot_id        			   			
						}
						
						
						res = @env.action_runner.run(SnapshotAction,env)
						
						#Now restore the vm to the previous state if running
						machine.action(:up) if prev_state==:running
						
						return res[:restore_result]
						
					end		
							
				rescue => e
					puts e.message
#					return nil				
				end
				
			end
			
			
					
			################################################################
			##################  VIRTUAL MACHINE PROVISION METHOD ##################
			################################################################
			def self.vm_provision(vmname)
				ensure_environment
			
				machine_names = []
	
				
				begin
				
					#Provisioning								
					get_vms(vmname).each do |machine|										
						machine_names << machine.name	
						machine.action(:provision)					
					end
					           
					
				
					machine_names
					
				rescue => e					
					puts e.message	
#					return nil			 
				end
				
			end
					
					
			################################################################
			###################  VIRTUAL MACHINE SSHCONFIG## ###############
			################################################################
			def self.vm_ssh_config(vmname)
				ensure_environment
				
				
				#Ensure vmname exists and it is not empty
				return nil if vmname.empty?
					
				
				begin
					info = Array.new
					get_vms(vmname).each do |machine|												
						info << machine.ssh_info						
					end
					
					info[0]
					
				rescue => e
					puts e.message
#					return nil
				end	
			
			end
		
			################################################################
			############  VIRTUAL MACHINE BACKUP TAKE METHOD #############
			################################################################
			def self.vm_snapshot_take_file(vmname)
				ensure_environment
				
				current_machine = nil
				t = Time.now.strftime "%Y-%m-%d %H:%M:%S"
				begin
				  
					machines=get_vms(vmname)
					
					return [404,"Virtual Machine not found"] if machines.empty?
										
					machines.each do |machine|						
						
						current_machine = machine.name.to_s						
						
						env = 
						{							
							:machine        => machine,
							:machine_action => SnapshotAction::BACKUP,
							:path						=> @env.data_dir
						}
						
						@db.add_backup_log_entry(t,current_machine,BACKUP_IN_PROGRESS)
		
						res = @env.action_runner.run(SnapshotAction,env)
						
						if res[:bak_filename] == SnapshotAction::ERROR
							@db.update_backup_log_entry(t,current_machine,BACKUP_ERROR)
							return [500,"Internal Error"] if res[:bak_filename] == SnapshotAction::ERROR
						else					
							@db.update_backup_log_entry(t,current_machine,BACKUP_SUCCESS)
							return [200,res[:bak_filename]]
						end
						
					end	
							
				rescue => e					
					@db.update_backup_log_entry(t,current_machine,BACKUP_ERROR)
					return [500,"Internal Error"]				
				end
				
			end
			
			
			
			################################################################
			#################  BACKUP LOG METHOD ###############
			################################################################
			def self.backup_log(vmname)
				ensure_environment				
				
				begin
				
					@db.get_backup_log_entries(vmname)
					
				rescue => e
					puts e.message									
				end
				
			end
			
			
			################################################################
			#######################  PRIVATE METHODS #######################
			################################################################
			private
			
			BACKUP_ERROR = "ERROR"
			BACKUP_SUCCESS = "OK"
			BACKUP_IN_PROGRESS = "IN PROGRESS"
			
			def self.ensure_environment
				#Due to the fact that the enviroment data can change
				#if we always use a stored value of env we won't be
				#able to notice those changes 				
#				if (!@env)
#					opts = {}					
#					@env = Vagrant::Environment.new(opts)					
#				end				
				
				opts = {}					
				@env = Vagrant::Environment.new(opts)
				@db = DB::DBManager.new(@env.data_dir) if (!@db)
				
			end
			
			#FIXME REVISAR Y MEJORAR, LO HE HECHO DEPRISA PERO SE 
			#PUEDE OPTIMIZAR
			def self.get_vms(vmname)				
				machines = []
				provider=@env.default_provider
							
				if (vmname && !vmname.empty?)
						#If a machine was specified launch only that machine									
						name=vmname.to_sym
					if (@env.machine_names.index(name)!=nil)
						
						@env.active_machines.each do |active_name, active_provider|
												
							if name==active_name							
								provider=active_provider
								break							
							end
																				
						end
						machines << @env.machine(name,provider)
					end
	
				else
					#If no machine was specified launch all
					@env.machine_names.each do |machine_name|
							@env.active_machines.each do |active_name, active_provider|								
								if active_name==machine_name
									provider=active_provider
									break
								end
								
							end
							machines << @env.machine(machine_name,provider)
					end			
				end		
				
				machines
				
			end
			
		end
	end
end
