require 'vagrant'
require 'vagrant-node/dbmanager'
require 'vagrant-node/pwmanager'
require 'vagrant-node/exceptions.rb'
require 'singleton'

module Vagrant
module Node

	class ObManager

		include Singleton

		
		
		def env
			@env
		end

		def env=(environment)
			@env=environment
			@db=nil
			@pw=nil
			@db = DB::DBManager.new(@env.data_dir) if (!@db)
			@pw = PwManager.new(@db) if (!@pw)
		end

		def dbmanager			
			@db
		end

		def pwmanager			
			@pw
		end

		
	end
end
end