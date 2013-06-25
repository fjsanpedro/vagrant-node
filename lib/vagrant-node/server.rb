require 'rubygems'
require 'vagrant-node/api'
require 'vagrant-node/pidfile'
require 'webrick'


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
				def self.run(pid_path,log_path,port=DEFAULT_BIND_PORT)
					pid_file = File.join(pid_path,PIDFILENAME)
								
					pid = fork do
					
						
						log_file = File.open (log_path + LOG_FILE).to_s, 'a+'
						
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
						
						begin
							server = WEBrick::HTTPServer.new(options)	
							
							server.mount "/", Rack::Handler::WEBrick,ServerAPI::API.new
							trap("INT") { server.stop }
						
							PidFile.create(pid_file,Process.pid)						
							
							server.start
							
							
						rescue Exception => e  
								puts e.message 
						end
					
					#Alternative running mode
	#				ServerAPI::API.run! :bind => '0.0.0.0', :port => 1234					
					end
					
				end
				
				def self.stop(pid_path)
					begin
						
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
										
					rescue Exception => e  
						puts e.message
					end 
										
				end
				
				
					
			end
		end
  end
end
