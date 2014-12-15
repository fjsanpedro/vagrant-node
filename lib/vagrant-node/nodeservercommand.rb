require 'vagrant/plugin'
require 'vagrant-node/api'
require 'vagrant-node/server'

module Vagrant
	module Node
	
		class Command < Vagrant.plugin(2, :command)
			START_COMMAND = "start"
			STOP_COMMAND = "stop"
			def initialize(argv, env)
		      super

		      @main_args, @sub_command, @sub_args = split_main_and_subcommand(argv)
					@subcommands = Vagrant::Registry.new
					
					@subcommands.register(:start) do
						require File.expand_path("../nodeserverstart", __FILE__)
						NodeServerStart
					end
					
					@subcommands.register(:stop) do
						require File.expand_path("../nodeserverstop", __FILE__)
						NodeServerStop
					end
					
					@subcommands.register(:passwd) do
            require File.expand_path("../nodeserverpasswd", __FILE__)
            NodeServerPasswd
          end
					
#				puts "MAIN ARGS #{@main_args}"
#				puts "SUB COMMAND #{@sub_command}"
#				puts "SUB ARGS #{@sub_args}"
			end
			
			def execute
				if @main_args.include?("-h") || @main_args.include?("--help")
					# Print help
					return help
				end

				command_class = @subcommands.get(@sub_command.to_sym) if @sub_command
				return help if !command_class || !@sub_command
				
				@logger.debug("Invoking command class: #{command_class} #{@sub_args.inspect}")
				
				command_class.new(@sub_args, @env).execute
				
#				case @sub_command
#					when START_COMMAND then
#						@env.lock_path contiene la ruta al fichero de lock
						#incluyendo el nombre de este, por lo tanto se pasa
						#únicamente la ruta						
#						ServerAPI::ServerManager.run(File.dirname(@env.lock_path))
#					when STOP_COMMAND then
#						ServerAPI::ServerManager.stop(File.dirname(@env.lock_path))
#					else
#						return help
#				end				
				0
			end
			
			def help
				
				opts = OptionParser.new do |opts|
					opts.banner = "Usage: vagrant nodeserver <command>"
					opts.separator ""
					opts.on("-h", "--help", "Print this help.")
					opts.separator ""
					opts.separator "Available subcommands:"				
					opts.separator "     start"
					opts.separator "     stop"
					opts.separator "     passwd"
					opts.separator ""
				end
				
				@env.ui.info(opts.help, :prefix => false)
				
			end
		end
		
	end
end
