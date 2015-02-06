require 'optparse'
require 'vagrant-node/server'
require 'io/console'
require 'vagrant-node/dbmanager'

module Vagrant
  module Node
	class NodeServerPasswd < Vagrant.plugin(2, :command)

    def ask_for_config
      puts "Configuring Vagrant Node"
      puts "Insert database user:"
      user=STDIN.noecho(&:gets).chomp
      print "\n"
      print "Insert database password:"
      password=STDIN.noecho(&:gets).chomp
      print "\n"
      print "Insert database name:"
      database=STDIN.noecho(&:gets).chomp
      print "\n"

      DB::DBManager.create_config_file(@env.data_dir,'localhost',database,user,password)

      DB::DBManager.check_bbdd_structure

    end

		def execute
	     options = {}

          opts = OptionParser.new do |opts|
            opts.banner = "Usage: vagrant nodeserver passwd"
          end
          
          # argv = parse_options(opts)
          # raise Vagrant::Errors::CLIInvalidUsage, :help => opts.help.chomp if argv.length > 1
          
          
          
          # if (argv.length==0)
  
            i=0


            begin    

              if (!DB::DBManager.check_config_file(@env.data_dir))

                

                puts "Configuring Vagrant Node"
                print "Insert privileged database user:  "
                user=STDIN.cooked(&:gets).chomp
                
                print "Insert privileged database user password:  "
                password=STDIN.noecho(&:gets).chomp
                print "\n"
                print "Insert database name:  "
                database=STDIN.cooked(&:gets).chomp
                print "\n"

                DB::DBManager.create_config_file(@env.data_dir,'localhost',database,user,password)


              end

              
              db = DB::DBManager.new(@env.data_dir)  

            rescue Exception => e            
              
              if (!DB::DBManager.check_config_file(@env.data_dir))
                retry
              end
              
              if (e.class==Mysql2::Error)              
                print "Can't connect to mysql with current configuration, please review provided credentials. Please execute again this command to reconfigure"
                DB::DBManager.delete_config_file(@env.data_dir)                
              end
              
            end
            
            if (!db.nil?)
              #Checking if user knows the old password
              if (db.node_password_set? && !db.node_default_password_set?)              
                print "Insert current password: "
                old_password=STDIN.noecho(&:gets).chomp
                print "\n"
                if !db.node_check_password?(old_password)
                  @env.ui.error("Password failed!")
                  return 0
                end            
              end
              
              pass_m = "Insert your new password for this Node: "
              confirm_m = "Please Insert again the new password: "
              
     
              if STDIN.respond_to?(:noecho)
                print pass_m
                password=STDIN.noecho(&:gets).chomp
                print "\n#{confirm_m}"
                confirm=STDIN.noecho(&:gets).chomp
                print "\n"
              else
                #FIXME Don't show password 
                password = @env.ui.ask(pass_m)
                confirm = @env.ui.ask(confirm_m)
              end
              
              if (password==confirm)              
                db.node_password_set(password)
                @env.ui.success("Password changed!")
              else
                @env.ui.error("Passwords does not match!")
              end
            end
  
  
  
            
                 
          
          
          		         		
          0
        end
        
	end
  end
end
