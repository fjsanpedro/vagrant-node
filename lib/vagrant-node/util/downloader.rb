require 'pp'
require "vagrant/util/busy"

require "vagrant/util/subprocess"

module Vagrant
  module Node
    module Util
      # This class downloads files using various protocols by subprocessing
      # to cURL. cURL is a much more capable and complete download tool than
      # a hand-rolled Ruby library, so we defer to it's expertise.
      class Downloader
        UPDATETIME = 10

        def initialize(source, destination, options=nil)          
          @source      = source.to_s
          @destination = destination.to_s

          # Get the various optional values
          options     ||= {}
          #@callback    = options[:callback]
          @insecure    = options[:insecure]
          @ui          = options[:ui]
          @db          = options[:db]
          @box_name          = options[:box_name]
        end

        # This executes the actual download, downloading the source file
        # to the destination with the given opens used to initialize this
        # class.
        #
        # If this method returns without an exception, the download
        # succeeded. An exception will be raised if the download failed.
        def download!          
          # Build the list of parameters to execute with cURL
          options = [
            "--fail",
            "--location",
            "--max-redirs", "10",
            "--output", @destination
          ]

          options << "--insecure" if @insecure
          options << @source

          # Specify some options for the subprocess
          subprocess_options = {}

          # If we're in Vagrant, then we use the packaged CA bundle
          if Vagrant.in_installer?
            subprocess_options[:env] ||= {}
            subprocess_options[:env]["CURL_CA_BUNDLE"] =
              File.expand_path("cacert.pem", ENV["VAGRANT_INSTALLER_EMBEDDED_DIR"])
          end

          # This variable can contain the proc that'll be sent to
          # the subprocess execute.
          data_proc = nil

          subprocess_options[:notify] = :stderr

          progress_data = ""
          progress_regexp = /(\r(.+?))\r/

          # Setup the proc that'll receive the real-time data from
          # the downloader.
          last_id=@db.add_box_download_info(@box_name,@source)
          
          comienzo = Time.now();
          
          data_proc = Proc.new do |type, data|
            # Type will always be "stderr" because that is the only
            # type of data we're subscribed for notifications.

            # Accumulate progress_data
            progress_data << data
          

            
            while true
              # If we have a full amount of column data (two "\r") then
              # we report new progress reports. Otherwise, just keep
              # accumulating.
              match = progress_regexp.match(progress_data)
              break if !match
              data = match[2]
              progress_data.gsub!(match[1], "")

              # Ignore the first \r and split by whitespace to grab the columns
              columns = data.strip.split(/\s+/)

              # COLUMN DATA:
              #
              # 0 - % total
              # 1 - Total size
              # 2 - % received
              # 3 - Received size
              # 4 - % transferred
              # 5 - Transferred size
              # 6 - Average download speed
              # 7 - Average upload speed
              # 9 - Total time
              # 9 - Time spent
              # 10 - Time left
              # 11 - Current speed
              
              if (Time.now()-comienzo > UPDATETIME)                
                @db.update_box_download_info(last_id,"#{columns[0]}%","#{columns[10]}")
                comienzo = Time.now()
              end

              #db.execute("INSERT INTO #{PASSWORD_TABLE} VALUES (\"#{DEFAULT_NODE_PASSWORD}\");");       
              #pp "Progress: #{columns[0]}% (Rate: #{columns[11]}/s, Estimated time remaining: #{columns[10]})"

              #output = "Progress: #{columns[0]}% (Rate: #{columns[11]}/s, Estimated time remaining: #{columns[10]})"
              ##@ui.clear_line
              #@ui.info(output, :new_line => false)
            end

            #@db.update_box_download_info(last_id,"100%","--:--:--")
          end
          

          # Add the subprocess options onto the options we'll execute with
          options << subprocess_options

          # Create the callback that is called if we are interrupted
          interrupted  = false
          int_callback = Proc.new do            
            interrupted = true
          end

          
          # Execute!
          result = Vagrant::Util::Busy.busy(int_callback) do
            Vagrant::Util::Subprocess.execute("curl", *options, &data_proc)
          
            
          end
          

          if ((!interrupted) && (result.exit_code==0))
              # @db.update_box_download_info(last_id,"100%","--:--:--")                            
              @db.delete_box_download(last_id)
          else                                              
              @db.set_box_download_error(last_id)
          end
          
          
          # If the download was interrupted, then raise a specific error
          raise Errors::DownloaderInterrupted if interrupted

          
          # If we're outputting to the UI, clear the output to
          # avoid lingering progress meters.
          @ui.clear_line if @ui

          
          # If it didn't exit successfully, we need to parse the data and
          # show an error message.
          if result.exit_code != 0
            
            @logger.warn("Downloader exit code: #{result.exit_code}") if @logger
            
            parts    = result.stderr.split(/\n*curl:\s+\(\d+\)\s*/, 2)
            
            parts[1] ||= ""
            
            

            raise Errors::DownloaderError, :message => parts[1].chomp
          end

          

          # Everything succeeded
          true
        end
      end
    end
  end
end
