require 'optparse'
require 'vagrant-node/server'
module Vagrant
  module Node
	class NodeServerStart < Vagrant.plugin(2, :command)
		def execute
	    #FIXME EVLUAR SI MERECE LA PENA EL PASAR LA PASS POR LINEA DE COMANDOS
      # options = {}
      # options[:password]= ""
        
      opts = OptionParser.new do |opts|
        opts.banner = "Usage: vagrant nodeserver start [port=3333] -p password"
        opts.separator ""
        # opts.on("-p", "--passwd password", String, "Node Password") do |b|
              # options[:password] = b
        # end
      end        
          
      argv = parse_options(opts)
      return if !argv  
      raise Vagrant::Errors::CLIInvalidUsage, :help => opts.help.chomp if argv.length > 1
      		
  		begin                        
			 #ServerAPI::ServerManager.run(File.dirname(@env.lock_path),@env.data_dir,@env,argv[0].to_i)       
       ServerAPI::ServerManager.run(@env.tmp_path,@env.data_dir,@env,argv[0].to_i)       
			rescue Exception => e  
        @env.ui.error(e.message)
      end 
	   
      0
    end
        
	end
  end
end
