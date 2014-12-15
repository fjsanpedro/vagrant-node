require 'optparse'
require 'vagrant-node/server'
module Vagrant
  module Node
	class NodeServerStop < Vagrant.plugin(2, :command)
		def execute
      # options = {}
      # options[:password]= ""
     
      opts = OptionParser.new do |opts|
        opts.banner = "Usage: vagrant nodeserver stop --passwd password"
        opts.separator ""
        # opts.on("-p","--passwd password", String, "Node Password") do |p|            
            # options[:password] = p
        # end
      end
      
      argv = parse_options(opts)
      return if !argv  
      raise Vagrant::Errors::CLIInvalidUsage, :help => opts.help.chomp if argv.length > 1 
      
      begin
        #ServerAPI::ServerManager.stop(File.dirname(@env.lock_path),@env.data_dir)
        ServerAPI::ServerManager.stop(@env.tmp_path,@env.data_dir)
      rescue Exception => e  
        @env.ui.error(e.message)
      end
       		         		
      0
    end
        
	end
  end
end
