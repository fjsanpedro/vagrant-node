require 'optparse'
require 'vagrant-node/server'
module Vagrant
  module Node
	class NodeServerStart < Vagrant.plugin(2, :command)
		def execute
	     options = {}

          opts = OptionParser.new do |opts|
            opts.banner = "Usage: vagrant nodeserver start [port=3333]"
          end
          
          argv = parse_options(opts)
          return if !argv  
          raise Vagrant::Errors::CLIInvalidUsage, :help => opts.help.chomp if argv.length > 1
      		
					ServerAPI::ServerManager.run(File.dirname(@env.lock_path),@env.data_dir,argv[0].to_i)
          		         		
          0
        end
        
	end
  end
end
