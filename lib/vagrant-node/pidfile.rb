module Vagrant
  module Node
	module ServerAPI
		class PidFile
			
			#FIXME en realidad no haría falta pasar el pid
			#ya que se puede coger el del hilo en curso con
			#el Process.pid
			def self.create(pid_file,pid)
			
				#Check first if pid_file exists
				if File.exists?(pid_file)										
					#Check if the stored pid belongs to a 
					#running process
					pidold = open(pid_file, 'r').read.to_i
					if process_exist?(pidold)
						raise 'Process #{pidold} is still alive and running'  
					else						
						#If it is not alive then remove the file
						delete(pid_file)
					end
				end			   
			    
				lock = open(pid_file, "w")
   				lock.flock(File::LOCK_EX | File::LOCK_NB) || raise				
   				lock.puts pid
   				lock.flush
   				lock.rewind
			end
			
			def self.delete(pid_file)				
				File.delete pid_file
			end
			
			private
			
			def self.process_exist?(pid)
				begin					
					Process.kill(0, pid)					
					true
				rescue Errno::ESRCH, TypeError					 
					false
				end
			end 
			
		end
	end
  end
end
