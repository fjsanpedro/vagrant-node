
require 'vagrant'
require 'vagrant-node/actions/snapshot'

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
								
				return fboxes
				
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
								
				return boxes
				
			end
			
			################################################################
			########################  BOX ADD METHOD #######################
			################################################################			
			def self.box_add(box,url)
			
				ensure_environment
				
				boxes = []			

				#TODO
			  								
				return boxes
				
			end
			
			################################################################
			##################  VIRTUAL MACHINE UP METHOD ##################
			################################################################
			def self.vm_up(vmname)
				ensure_environment
			
				machine_names = []
	
				begin
				
					#FIXME DELETE
		#								puts @env.active_machines
		#								puts @env.machine_names
					#					
				
					options = {}
					options[:parallel] = true
				
					#Lanzando las máquinas
					@env.batch(options[:parallel]) do |batch|			
						get_vms(vmname).each do |machine|				
							machine_names << machine.name	
							batch.action(machine, :up, options)					
						end
					end           
					
				
					return machine_names
					
				rescue => e
					#FIXME DELETE
					puts e.message	
					return nil			 
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
								
					return machine_names
					
				rescue => e
					#FIXME DELETE
					puts e.message
					return nil
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
							
					return machine_names
				
				rescue => e
					#FIXME DELETE
					puts e.message
					return nil
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
							
						status << {"name" => machine.name.to_s.ljust(25),
									"status" => machine.state.short_description,
									"provider" => machine.provider_name}
					end		
				
				
					return status
							
				rescue => e
					puts e.message
					return nil				
				end
				
			end
			
			################################################################
			##################  VIRTUAL MACHINE SUSPEND METHOD ##################
			################################################################
			def self.vm_suspend(vmname)
				ensure_environment
			
				machine_names = []
			
				begin
				
					
					#Suspendiendo las máquinas								
					get_vms(vmname).each do |machine|				
						machine_names << machine.name	
						machine.action(:suspend)
					end           
					
				
					return machine_names
					
				rescue => e					
					puts e.message	
					return nil			 
				end
				
			end
		
			################################################################
			##################  VIRTUAL MACHINE RESUME METHOD ##################
			################################################################
			def self.vm_resume(vmname)
				ensure_environment
			
				machine_names = []
	
				puts "VMNAME ES #{vmname}"
				begin		
									
				
					
				
					#Lanzando las máquinas
								
					get_vms(vmname).each do |machine|
						puts "MACHINE #{machine.name}"				
						machine_names << machine.name	
						machine.action(:resume)					
					end
					           
					
				
					return machine_names
					
				rescue => e					
					puts e.message	
					return nil			 
				end
				
			end
			
			################################################################
			############  VIRTUAL MACHINE SNAPSHOT LIST METHOD #############
			################################################################
			def self.vm_snapshots(vmname)
				ensure_environment				
				
				begin
				
					snapshots = {}
						#machine.run_action(Fran)
						#@env.action_runner.run(:Fran)
          #@env.run_action(SnapshotAction)				
					get_vms(vmname).each do |machine|
						
						env = 
						{							
        			:machine        => machine,
        			:machine_action => SnapshotAction::LIST
						}
						
						
						res = @env.action_runner.run(SnapshotAction,env)
						
						snapshots[machine.name.to_sym]=res[:snapshots_list]
						
					end		
				
				
					return snapshots
							
				rescue => e
					puts e.message
					return nil				
				end
				
			end
			
			################################################################
			############  VIRTUAL MACHINE SNAPSHOT TAKE METHOD #############
			################################################################
			def self.vm_snapshot_take(vmname,name,desc=" ")
				ensure_environment				
				
				begin
				
					snapshot = {}
										
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
					return nil				
				end
				
			end
			
			################################################################
			############  VIRTUAL MACHINE SNAPSHOT RESTORE METHOD #############
			################################################################
			def self.vm_snapshot_restore(vmname,snapshot_id)
				ensure_environment				
				
				begin
				
					snapshot = {}
										
					get_vms(vmname).each do |machine|
						env = 
						{							
        			:machine        => machine,
        			:machine_action => SnapshotAction::RESTORE,
        			:snapshot_id 	=> snapshot_id        			   			
						}
						
						
						res = @env.action_runner.run(SnapshotAction,env)
						
						return res[:restore_result]
						
					end		
				
								
							
				rescue => e
					puts e.message
					return nil				
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
					           
					
				
					return machine_names
					
				rescue => e					
					puts e.message	
					return nil			 
				end
				
			end
					
					
			################################################################
			###################  VIRTUAL MACHINE SSHCONFIG## ###############
			################################################################
			def self.vm_ssh_config(vmname)
				ensure_environment
				
				#Ensure vmname exists and it is not empty
				if vmname.empty?
					return nil
				end
				
				begin
					#FIXME Change array due to we only want one result
					info = Array.new
					get_vms(vmname).each do |machine|						
						info << machine.ssh_info
					end
					
					return info[0]
				rescue => e
					puts e.message
					return nil
				end	
			
			end
		
			
			
			################################################################
			#######################  PRIVATE METHODS #######################
			################################################################
			private
			
			def self.ensure_environment				
				if (!@env)
					opts = {}					
					@env = Vagrant::Environment.new(opts)					
				end							
					
			end
			
			#FIXME REVISAR Y MEJORAR, LO HE HECHO DEPRISA PERO SE 
			#PUEDE OPTIMIZAR
			def self.get_vms(vmname)				
				machines = []
				provider=@env.default_provider
							
				if (vmname && !vmname.empty?)
					#Si se especifica el nombre de una máquina concreta									
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
					#Si no se ha especificado ninguna máquina entonces se lanzan todas
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
				
				return machines
				
			end
		
		
		
		
		#BACKUP
		#FIXME en vez de con @env.active_machines, ya que no tendría
		#en cuenta las vm no creadas, se utiliza @env.machine_names
#		def self.get_vms(vmname)				
#			machines = []
#			if (vmname && !vmname.empty?)				
#				Si se especifica el nombre de una máquina concreta						
#				name=vmname.to_sym				
#				@env.active_machines.each do |active_name, active_provider|					
#					if name==active_name								
#					machines << @env.machine(name,active_provider)
#
#					end								
#				end
#
#			else
#				Si no se ha especificado ninguna máquina entonces se lanzan todas
#				@env.active_machines.each do |active_name, active_provider|
#			
#					if (@env.machine_names.index(active_name)!=nil)								
#						machines << @env.machine(active_name,active_provider)
#					end							
#				end			
#			end				
#			
#			puts "EN GET_VMS machines vale #{machines}"
#			
#			return machines
#			
#		end
			
		end
	end
end
