require 'vagrant-node/dbmanager'

module Vagrant
  module Node
    class PwManager
      def initialize(db)
        @dbmanager=db
      end      
      
      #Token is a MD5 token
      #challenge was the 
      def authorized?(token,challenge)
        #FIXME REMOVE
        # pp "CHECKING PASSWORD"
        # pp "TOKEN = #{token}"
        # pp "CHALLENGED = #{Digest::MD5.hexdigest(challenge+@dbmanager.node_password)}"    
        #pp "EN HEX DIGEST #{Digest::MD5.hexdigest(challenge+@dbmanager.node_password)}"    
        return token==Digest::MD5.hexdigest(challenge+@dbmanager.node_password)        
      end
      
    end
  end
end
