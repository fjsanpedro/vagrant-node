require "vagrant-node/version"

module Vagrant
  module Node
    class Plugin < Vagrant.plugin("2")
    
    	name "server"
    	description <<-DESC
    	ESTE PLUGIN ES EL QUE LANZA EL SERVIDOR
    	DESC
    	
		
			command ('server') do
					require_relative "vagrant-node/servercommand"
					Command
			end
		
		
    end
  end
end
