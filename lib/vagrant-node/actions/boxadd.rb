  require 'pp'
require 'rubygems'
require 'vagrant-node/util/downloader'
require "vagrant/util/platform"
require 'vagrant-node/obmanager'

module Vagrant
  module Node
  	class BoxAddAction
  		def initialize(app, env)
          @app    = app          
        end

        def call(env)
          @temp_path = env[:tmp_path].join("box" + Time.now.to_i.to_s)
          

          url = env[:box_url]
          if File.file?(url) || url !~ /^[a-z0-9]+:.*$/i          
            file_path = File.expand_path(url)
            file_path = Util::Platform.cygwin_windows_path(file_path)
            url = "file:#{file_path}"
          end

          downloader_options = {}
          downloader_options[:callback] = env[:callback]
          downloader_options[:insecure] = env[:box_download_insecure]
          downloader_options[:ui] = env[:ui]
          downloader_options[:db] = env[:db]
          downloader_options[:box_name] = env[:box_name]




          # Download the box to a temporary path. We store the temporary
          # path as an instance variable so that the `#recover` method can
          # access it.
          #env[:ui].info(I18n.t("vagrant.actions.box.download.downloading"))
          

          begin
            downloader = Util::Downloader.new(url, @temp_path, downloader_options)
            downloader.download!            
          rescue Errors::DownloaderInterrupted
            # The downloader was interrupted, so just return, because that
            # means we were interrupted as well.
            #env[:ui].info(I18n.t("vagrant.actions.box.download.interrupted"))
            return          
          rescue Errors::DownloaderError => msg
            #puts msg.message.split(/\r\n/).inspect.length

            #puts "CONTROLAR ESTE MENSAJE DE ERROR"
            

            return
          end

          # Add the box
          #env[:ui].info I18n.t("vagrant.actions.box.add.adding", :name => env[:box_name])
          added_box = nil
          error=false

          begin

            #last_id=env[:db].add_box_uncompression(env[:box_name],url)        
            last_id=ObManager.instance.dbmanager.add_box_uncompression(env[:box_name],url)        
            
            added_box = env[:box_collection].add(
              @temp_path, env[:box_name], env[:box_provider], env[:box_force])
            
            error=false
          rescue Vagrant::Errors::BoxUpgradeRequired
            
            error=true
            # Upgrade the box
            #@db.set_box_uncompression_error(last_id)            

            env[:box_collection].upgrade(env[:box_name])

            # Try adding it again
            retry
          end


          #env[:db].clear_box_uncompression(last_id) if (error==false)
          #env[:db].clear_box_uncompression(last_id)
          ObManager.instance.dbmanager.clear_box_uncompression(last_id)

          #env[:db].close_db_connection
          # Call the 'recover' method in all cases to clean up the
          # downloaded temporary file.
          recover(env)

          # Success, we added a box!
          #env[:ui].success(
           # I18n.t("vagrant.actions.box.add.added", name: added_box.name, provider: added_box.provider))

          # Carry on!
          @app.call(env)
        end

        def recover(env)
          if @temp_path && File.exist?(@temp_path)
            File.unlink(@temp_path)
          end
        end
  	end
  end
end	

