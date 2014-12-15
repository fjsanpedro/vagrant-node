require 'vagrant-node/dbmanager'

module Vagrant
  module Node
    class PwManager
      def initialize(db)
        @dbmanager=db
        puts "fran"
        puts @dbmanager
      end      
      
    end
  end
end
