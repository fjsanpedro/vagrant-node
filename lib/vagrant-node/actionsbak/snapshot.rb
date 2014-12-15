require 'pp'
require "rexml/document"
require 'rubygems'
require 'zip/zip'


module Vagrant
  module Node
  	
  	class SnapshotAction
  		LIST = :list
  		TAKE = :take
  		DELETE = :delete
  		RESTORE = :restore
  		BACKUP = :backup
  		ERROR = :error
  		
			def initialize(app, env)
				@app = app
			end
		
			def call(env)
				
				#FIXME generate a result code error to this case in order 
				#to provide more info to the client
				raise RestException.new(406,"Couldn't perform the operation because machine is not yet created") if env[:machine].state.id==:not_created    
				#return @app.call(env) if env[:machine].state.id==:not_created
				
				current_driver=env[:machine].provider.driver
				
				begin				
					current_driver.check_snapshot_stuff
				rescue Exception => e
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
					when DELETE then					             
            env[:delete_result]=current_driver.delete_snapshot(env[:snapshot_id])            
					when BACKUP then
						env[:bak_filename]=current_driver.backup_vm(env[:machine].name.to_s,env[:machine].data_dir)
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
          
          raise RestException.new(400,"Snapshot name can't be emtpy") if name.empty?						
					
					#Snapshots with the same name are not allowed
					begin
					   #if this command doesn't fail means that there is a snapshot with the same name
					   execute("snapshot",self.uuid,"showvminfo",name)					   
					   raise RestException.new(400,"There is a snapshot with the same name, please choose another name for the new snapshot")
					rescue Vagrant::Errors::VBoxManageError => e
					  #Doing nothing continue with the snapshot creation
					end
					 
					
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
					
					
					#return snapshot
					snapshot
						
						
				end #driver.take_snapshot
			
				def driver.delete_snapshot(snapid)
				  raise RestException.new(400,"Snapshot Identifier can't be emtpy") if snapid.empty?
				  begin
  				  execute("snapshot",self.uuid,"delete",snapid)
  				  return true
				  rescue =>e
  			   if e.message =~ /VBOX_E_OBJECT_NOT_FOUND/
  			     raise RestException.new(404,"The snapshot identifier provided doesn't exist")
  			   elsif e.message =~ /NS_ERROR_FAILURE/
  			     raise RestException.new(500,"Internal VBoxManage Error: can't delete the snapshot, try shutting down the Vm")
  			   else
  			    raise RestException.new(500,"Internal VBoxManage Error")
  			   end  				   
				  end
				end 
				
				
				
				def driver.backup_vm(vmname,path)						
					
					zipfilename=nil
					begin
						#Execute the export command
						
						
						time = Time.now						
						basename = "Backup.#{vmname}.#{time.year}.#{time.month}.#{time.day}.#{time.hour}.#{time.min}.#{time.sec}"
						zipfilename = path.to_s + '/'+ basename + '.zip'
						
						vmdir = nil
						execute("showvminfo",self.uuid,"--machinereadable").split("\n").each do |line|
							vmdir = File.dirname($1) if line =~ /^CfgFile="(.*?)"$/													 
						end

						
						Zip::ZipFile.open(zipfilename, Zip::ZipFile::CREATE) do |zipfile|
								Dir[File.join(vmdir, '**', '**')].each do |file|									
									zipfile.add(file.sub(vmdir+"/", ''), file)
								end
						end
							
						zipfilename					
						
					rescue => e						
						File.delete(zipfilename) if File.exists?(zipfilename)
						return ERROR
					end
						
						
				end #driver.backup_vm
				
				
				
#				def driver.export_vm(path)						
#					
#					begin
						#Execute the export command
#						basename = "Backup.#{Time.now.to_i.to_s}"
#						filename = path + basename
#						execute("export",self.uuid,"--output",filename.to_s+".ovf")
#						zipfilename = filename.to_s + '.zip'
#						
#						files_to_zip = []
#						Dir.chdir(path)
#						Dir.glob(basename+"*") do |file|
#							files_to_zip << file
#						end
#						
#						Zip::ZipFile.open(zipfilename, Zip::ZipFile::CREATE) do |zipfile|
#							files_to_zip.each do |file|
#								zipfile.add(file,file)
#							end
#						end
#												
#						
#						Cleaning files						
#						files_to_zip.each do |file|
#							File.delete(file)								
#						end
#						return zipfilename					
#						
#					rescue => e
#						puts e.message
#						return ERROR
#					end
						
						
				#end #driver.export_vm
				
				
				def driver.list
					config = nil
					current_snapshot = nil
					
					execute("showvminfo",self.uuid,"--machinereadable").split("\n").each do |line|
						config = $1 if line =~ /^CfgFile="(.*?)"$/
													
					end						
					
					snapshots = []				
					
					doc = REXML::Document.new File.new(config)
					machine = doc.elements["VirtualBox/Machine"]
					
					@current_snapshot = machine.attributes["currentSnapshot"]
					
					snapshots = search_snapshot(machine) if @current_snapshot
					
					
					snapshots						
					
						
				end #driver.list
				
				def driver.search_snapshot(path)
					
					snapshots = []
					if path					
						path.elements.each("Snapshot") { |element|
							snapshot = {}
							original_uuid = element.attributes["uuid"]	
							snapshot[:uuid] = original_uuid[1..original_uuid.length-2]							
							snapshot[:name] = element.attributes["name"]							
							snapshot[:timestamp] = element.attributes["timeStamp"]
							
							if 	element.elements["Description"]						
								snapshot[:description] =	element.elements["Description"].text
							else 
								snapshot[:description] =	" "
							end
							
							if (original_uuid==@current_snapshot)
								snapshot[:current_state] = true
							else
								snapshot[:current_state] = false
							end
							
							snapshot[:snapshots] = search_snapshot(element.elements["Snapshots"])
							
							snapshots << snapshot						
						}
					end #driver.search_snapshot(path)
					
					#return snapshot array
					snapshots
					
				end

				#snapipd could be the snapshot uuid or its name
				def driver.restore_snapshot(snapid)						
						
					snapshots = []
					
					begin
													
						result = execute("snapshot",self.uuid,"restore",snapid)
						
						if result =~ /^Restoring snapshot\s(.*?)$/
								snapshots << $1									
						end
						
						#return snapshot array						
						snapshots
						
					rescue Vagrant::Errors::VBoxManageError => e
							return snapshots if e.message=~ /Could not find a snapshot named/						
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
				
