require 'optparse'
require 'vagrant-node/server'
module Vagrant
  module Node
	class NodeServerStop < Vagrant.plugin(2, :command)
		def execute
	     options = {}

          opts = OptionParser.new do |opts|
            opts.banner = "Usage: vagrant nodeserver stop"
          end
          
          argv = parse_options(opts)
          return if !argv  
          raise Vagrant::Errors::CLIInvalidUsage, :help => opts.help.chomp if argv.length > 1 
          
          ServerAPI::ServerManager.stop(File.dirname(@env.lock_path))		         		
          0
        end
        
	end
  end
end
