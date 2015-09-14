require 'vagrant'
require 'vagrant-node/dbmanager'
require 'vagrant-node/pwmanager'
require 'vagrant-node/exceptions.rb'
require 'singleton'


module Vagrant

end

module Vagrant
	module Config
		class Loader
			def procs_for_path(path)

				return Config.capture_configures do
					begin

						#Module hack to remove previous constans definitions
						modaux=Module.new
						res=modaux.module_eval(File.read(path))						
						obconstants = Object.constants


						modaux.constants.each do |var|
							Object.send(:remove_const,var) if Object.constants.include?(var)
						end
						############################33


						Kernel.load path
					rescue SyntaxError => e
						# Report syntax errors in a nice way.
						raise Errors::VagrantfileSyntaxError, :file => e.message
					rescue SystemExit
						# Continue raising that exception...
						raise
					rescue Vagrant::Errors::VagrantError
						# Continue raising known Vagrant errors since they already
						# contain well worded error messages and context.
						raise
					rescue Exception => e
						@logger.error("Vagrantfile load error: #{e.message}")
						@logger.error(e.backtrace.join("\n"))

						# Report the generic exception
						raise Errors::VagrantfileLoadError,
						  :path => path,
						  :message => e.message
						end
        	end
			end
		end
	end


	# class Environment

 #    	def reload

 #    		@config_global = nil
 #    		@config_loader = nil
 #    		@config_global = config_global


	# 		@config_global
 #    	end
 #    end

module Node



	class ObManager

		include Singleton

		def initialize
			@env = Environment.new
			@db = DB::DBManager.new(@env.data_dir) if (!@db)
			@pw = PwManager.new(@db) if (!@pw)
		end

		def env
			if (!@env)
				self.env=Environment.new
			end
			@env
		end

		def reload_env

			if (@env)
				@env.unload if (@env)
				# @env.reload
				@env = nil
			end

			@env = Environment.new
			self.env=@env

			@env
		end

		def env=(environment)
			@env=environment
			@db=nil
			@pw=nil
			@db = DB::DBManager.new(@env.data_dir) if (!@db)
			@pw = PwManager.new(@db) if (!@pw)
		end

		def dbmanager
			@db
		end

		def pwmanager
			@pw
		end


	end
end
end
