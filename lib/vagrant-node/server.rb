require 'rubygems'
require 'vagrant-node/api'
require 'vagrant-node/pidfile'
require 'webrick'
require 'vagrant-node/dbmanager'
require 'io/console'
#FIXME EVALUAR SI MERECE LA PENA HACER AUTENTICACION DE PASSWORD AQUI
#FIXME Problema con el logging ya que únicamnete
#vuelca al fichero todo cuando se acaba el proceso con el 
#vagrant server stop
module Vagrant
  module Node
		module ServerAPI
			class ServerManager
				PIDFILENAME = "server.pid"
				DEFAULT_BIND_PORT = 3333	
				BIND_ADDRESS = "0.0.0.0"
				LOG_FILE = "webrick.log"						
				def self.run(pid_path,data_path,env,port=DEFAULT_BIND_PORT)
					
					check_password(data_path)
					
					pid_file = File.join(pid_path,PIDFILENAME)
				        	
					pid = fork do
					
						
						log_file = File.open (data_path + LOG_FILE).to_s, 'a+'
						
						log = WEBrick::Log.new log_file
						
						access_log = [
							[log_file, WEBrick::AccessLog::COMBINED_LOG_FORMAT],
						]
						
						port = DEFAULT_BIND_PORT if port < 1024
						
						options = {
							:Port => port, 
							:BindAddress => BIND_ADDRESS,
							:Logger => log, 
							:AccessLog => access_log
						}
						
						
						#begin
							server = WEBrick::HTTPServer.new(options)	
							
							server.mount "/", Rack::Handler::WEBrick,ServerAPI::API.new
							
							trap("INT") { server.shutdown }

							trap("USR1") { 
								
								#Stopping server
								server.shutdown
								
								#Restarting server
								server = WEBrick::HTTPServer.new(options)
								server.mount "/", Rack::Handler::WEBrick,ServerAPI::API.new	
								server.start
							}

							PidFile.create(pid_file,Process.pid)						
							
							server.start
							
							
						# rescue Exception => e  
								# puts e.message 
						# end
					
					#Alternative running mode
	#				ServerAPI::API.run! :bind => '0.0.0.0', :port => 1234					
					end
					
				end
				
				def self.stop(pid_path,data_path)
					
						
						# check_password(data_path,passwd);
						
						
						pid_file = File.join(pid_path,PIDFILENAME)
						
						if !File.exists?(pid_file)
							return
						end
						
						
						pid = File.read(pid_file).to_i
						
						#Regardless the pid belongs to a running process or not
						#first delete the file
						PidFile.delete(pid_file)
						#FIXME No sé por qué cuando se crea un environment
						#en el cliente, el servidor deja de atrapar la señal 
						#de INT
						#Process.kill('INT', pid)
						Process.kill('KILL', pid)
						#Process.kill 9, pid	
										
					 
										
				end
				
				private

				
				def self.check_password(data_path)				  

					begin
					  	@db = DB::DBManager.new(data_path)					  
					rescue
						if (!@db || !@db.node_password_set? || @db.node_default_password_set?)
							raise "Please, set first a password with the command \"vagrant nodeserver passwd\""				  
						end
					end
				  true
				end
				
					
			end
		end
  end
end
