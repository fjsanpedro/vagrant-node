require 'pp'
require "rexml/document"
module Vagrant
  module Node
  	
  	class SnapshotAction
  		LIST = :list
  		TAKE = :take
  		RESTORE = :restore
			def initialize(app, env)
				@app = app
#				puts "Fran"
#				puts env
#				puts "Fran1"
			end
		
			def call(env)
				
				#FIXME generate a result code error to this case in order 
				#to provide more info to the client
				return @app.call(env) if env[:machine].state.id==:not_created
				
				current_driver=env[:machine].provider.driver
				
				begin				
					current_driver.check_snapshot_stuff
				rescue Exception => e
#					puts e.message
#					pp env[:machine].provider_name
					case env[:machine].provider_name.to_s					
						when "virtualbox" then							
							attach_vbox_methods(current_driver)
					end
					
				end
				
				case env[:machine_action]
					when LIST then
						env[:snapshots_list]=current_driver.list
					when TAKE then
						env[:last_snapshot]=current_driver.take_snapshot(env[:snapshot_name],env[:snapshot_desc])
					when RESTORE then
						env[:restore_result]=current_driver.restore_snapshot(env[:snapshot_id])
				end
				
				@app.call(env)
				
			end
			
			private
			
			def attach_vbox_methods(driver)
				
				def driver.check_snapshot_stuff
						return true
				end					
					
				#FIXME Si no se hace con --pause y la máquina esta running
				#se produce un error y deja a la máquina en estado 'gurumeditating'
				def driver.take_snapshot(name,description=" ")						
						
					begin
						#Execute the take command
						if (description)
							execute("snapshot",self.uuid,"take",name,"--description",description,"--pause")
						else
							execute("snapshot",self.uuid,"take",name,"--pause")
						end

						snapshot = {}						
						#Getting the uuid of the latest snapshot
						execute("snapshot",self.uuid,"list").split("\n").each do |line|
						
							if line =~ /Name:\s(.*?)\s\(UUID:\s(.*?)\)\s\*$/						
								snapshot[:name] = $1
								snapshot[:id] = $2
							end
						
						end
						
						return snapshot					
						
						
					rescue => e
						puts e.message
						return nil
					end
						
						
				end #driver.take_snapshot
				
				
				def driver.list
						config = nil
						current_snapshot = nil
#						puts self.uuid
						
						execute("showvminfo",self.uuid,"--machinereadable").split("\n").each do |line|
							config = $1 if line =~ /^CfgFile="(.*?)"$/
													 
						end
						#puts "CONFIG ES #{config}"
						
						snapshots = []				
						
						doc = REXML::Document.new File.new(config)
						machine = doc.elements["VirtualBox/Machine"]
						
						@current_snapshot = machine.attributes["currentSnapshot"]
						
						snapshots = search_snapshot(machine) if @current_snapshot
						
						
						return snapshots
#						doc.elements.each("VirtualBox/Machine/Snapshot") { |element|
#							snapshot = {} 
#							puts element.attributes["uuid"]
#							puts element.attributes["name"]
#							puts element.attributes["timeStamp"]
#							puts element.elements["Description"].text
#							
#							snapshot[:uuid] = element.attributes["uuid"]							
#							snapshot[:name] = element.attributes["name"]							
#							snapshot[:timestamp] = element.attributes["timeStamp"]							
#							snapshot[:description] =	element.elements["Description"].text						
#							snapshot[:current_state] = false							
#							
#						}
						
						
						
				end #driver.list
				
				def driver.search_snapshot(path)
					
					snapshots = []
					if path					
						path.elements.each("Snapshot") { |element|
							snapshot = {}
							
							snapshot[:uuid] = element.attributes["uuid"]							
							snapshot[:name] = element.attributes["name"]							
							snapshot[:timestamp] = element.attributes["timeStamp"]
							
							if 	element.elements["Description"]						
								snapshot[:description] =	element.elements["Description"].text
							else 
								snapshot[:description] =	" "
							end
							
							if (snapshot[:uuid]==@current_snapshot)
																					
								snapshot[:current_state] = true
							else
								snapshot[:current_state] = false
							end
							
							snapshot[:snapshots] = search_snapshot(element.elements["Snapshots"])
							
							snapshots << snapshot						
						}
					end #driver.search_snapshot(path)
					
					return snapshots
				end

				#snapipd could be the snapshot uuid or its name
				def driver.restore_snapshot(snapid)						
						
						snapshots = []
						
						begin
						
							result = execute("snapshot",self.uuid,"restore",snapid)
							
							if result =~ /^Restoring snapshot\s(.*?)$/
									snapshots << $1									
							end
																			
							return snapshots
						rescue Vagrant::Errors::VBoxManageError => e
								
								return snapshots if e.message=~ /Could not find a snapshot named/ 
								
								return nil 
						
						end
						
				end


				
			end # attach_vbox_methods(driver)		
			 
			
  	end
  	
  end
end

#				def driver.list
#						puts "LISTING SNAPSHOT"
#						begin
#						snapshots = []
#						puts "UUID #{self.uuid}"
#						execute("snapshot",self.uuid,"list").split("\n").each do |line|
#							snapshot = {}							
#
#							if line =~ /Name:\s(.*?)\s\(UUID:\s(.*?)\)$/								
#								snapshot[:name] = $1
#								snapshot[:id] = $2
#								snapshot[:current_state] = false						 	
#						 	elsif line =~ /Name:\s(.*?)\s\(UUID:\s(.*?)\)\s\*$/						
#								snapshot[:name] = $1
#								snapshot[:id] = $2
#								snapshot[:current_state] = true
#						 	end					
#						 	snapshots.push(snapshot)		
#						end
#						rescue Exception => e
#							puts e.message
#						end
#						
#						puts snapshots
#						return snapshots
#				end
				
#				SnapshotName="PRIMERA"
#SnapshotUUID="e81f74ce-5db5-418b-867e-16996503a1ae"
#SnapshotName-1="PRIMERA"
#SnapshotUUID-1="ae7599b5-e930-4ba2-a4da-934f1d938eaa"
#SnapshotName-1-1="PRIMERA"
#SnapshotUUID-1-1="7dd9f508-5d83-46a4-bc11-23eabcea54ee"
#
