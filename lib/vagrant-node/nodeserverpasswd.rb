require 'optparse'
require 'vagrant-node/server'
module Vagrant
  module Node
	class NodeServerPasswd < Vagrant.plugin(2, :command)
		def execute
	     options = {}

          opts = OptionParser.new do |opts|
            opts.banner = "Usage: vagrant nodeserver passwd"
          end
          
          argv = parse_options(opts)
          puts argv
          
          # choice = @env.ui.ask("Do you really want to destroy #{message} [N/Y]? ")
#           
          # if (!choice || choice.upcase != "Y" )                 
            # return 0        
          # end
          
          # return if !argv  
          # raise Vagrant::Errors::CLIInvalidUsage, :help => opts.help.chomp if argv.length > 1
#       		
					# ServerAPI::ServerManager.run(File.dirname(@env.lock_path),@env.data_dir,argv[0].to_i)
          		         		
          0
        end
        
	end
  end
end
