require "vagrant-node/version"
require 'vagrant/plugin'

module Vagrant
  module Node
    class Plugin < Vagrant.plugin("2")
    
    	name "node"
    	description <<-DESC
    	ESTE PLUGIN ES EL QUE LANZA EL SERVIDOR
    	DESC
    	
		
			command ('nodeserver') do
					require_relative "vagrant-node/nodeservercommand"
					Command
			end
		
		
    end
  end
end
