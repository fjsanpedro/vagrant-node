#require 'sqlite3'
require 'digest/md5'
require 'vagrant-node/exceptions.rb'
require 'mysql2'
require 'yaml'

module Vagrant
module Node
module DB
	class DBManager

		DOWNLOAD_ERROR=-1
		DOWNLOAD_STOP=0		
		DOWNLOAD_START=1
		DOWNLOAD_SUCCESS=2
		DOWNLOAD_UNCOMPRESS = 3

		def initialize(data_dir)
			@db=check_database(data_dir)
			@data_dir=data_dir
		end
		
		def get_backup_log_entries(vmname)
			sql="SELECT * FROM #{BACKUP_TABLE_NAME}"
			sql = sql + " WHERE #{BACKUP_VM_NAME_COLUMN} = \"#{vmname}\"" if vmname					
			
			#return rows
			@db.query(sql)
			
		end
		
		def add_backup_log_entry(date,vmname,status)
			sql="INSERT INTO #{BACKUP_TABLE_NAME} VALUES ( '#{date}' , '#{vmname}' , '#{status}' )"					
			@db.query(sql)
		end
		
		def update_backup_log_entry(date,vmname,status)					
			sql="UPDATE #{BACKUP_TABLE_NAME} SET #{BACKUP_STATUS_COLUMN} = '#{status}' WHERE #{BACKUP_DATE_COLUMN}= '#{date}' AND #{BACKUP_VM_NAME_COLUMN}= '#{vmname}'"
			@db.query(sql)					
		end
			
		def node_password_set?
		  sql="SELECT Count(*) FROM #{PASSWORD_TABLE};"
		  
		  return @db.query(sql).size!=0		  
		  
		end
      
        def node_check_password?(old_password)
          sql="SELECT #{PASSWORD_COLUMN} FROM #{PASSWORD_TABLE} LIMIT 1;"
          stored_pwd=@db.query(sql)
          
          return (stored_pwd.size!=0 && (stored_pwd.first[PASSWORD_COLUMN]==Digest::MD5.hexdigest(old_password)))  
          
        end
        
        def node_password
          sql="SELECT #{PASSWORD_COLUMN} FROM #{PASSWORD_TABLE} LIMIT 1;"
          stored_pwd=@db.query(sql)
          
          stored_pwd.first[PASSWORD_COLUMN]
        end
        
        def node_password_set(new_password,raw=false)          
        	password=((raw)? new_password:Digest::MD5.hexdigest(new_password))

          if node_password_set?  || !node_default_password_set?        
            sql="UPDATE #{PASSWORD_TABLE} SET #{PASSWORD_COLUMN} = '#{password}' "
          else            
            sql="INSERT INTO #{PASSWORD_TABLE} VALUES ('#{password}')"
          end
          
          @db.query(sql)
            
        end

        def node_default_password_set?
          return node_password == DEFAULT_NODE_PASSWORD 
        end


        def create_queued_process(id)
			tactual = Time.now.strftime("%Y-%m-%d")
			texp = Time.now.to_i
			sql="INSERT INTO #{OPERATION_QUEUE_TABLE_NAME} VALUES (#{id}, '#{tactual}', '#{texp}', #{PROCESS_IN_PROGRESS}, '')"
			#@db.execute(sql,id,Time.now.strftime("%Y-%m-%d") ,Time.now.to_i,PROCESS_IN_PROGRESS,"")          
			@db.query(sql)
        end
        
        def set_queued_process_result(id,result)
          sql="UPDATE #{OPERATION_QUEUE_TABLE_NAME} SET #{OPERATION_STATUS_COLUMN} = #{PROCESS_SUCCESS},#{OPERATION_RESULT_COLUMN} = '#{result}'  WHERE #{OPERATION_ID_COLUMN}= #{id}"          
          #@db.execute(sql,PROCESS_SUCCESS,result,id)
          @db.query(sql)
        end
        
        def set_queued_process_error(id,exception)          
          
          errlog = []		

          errcode=PROCESS_ERROR
          
          # decoded=exception.message.to_s.tr("\n"," ")
          # puts exception.message.to_s
          # pp exception.message.to_s
          # pp decoded

          

          if (exception.class==VMActionException)
          	errlog << {"vmname" => exception.vmname,"provider"=>exception.provider,"status" => exception.message.to_s.tr("\'","\"")}	
          elsif (exception.class==RestException)
          	errcode=exception.code
          	errlog << {"status" => exception.message.to_s.tr("\'","\"")}	          	
          else
          	errlog << {"status" => exception.message.to_s.tr("\'","\"")}	          	
          end
          
          
          
          sql="UPDATE #{OPERATION_QUEUE_TABLE_NAME} SET #{OPERATION_STATUS_COLUMN} = #{errcode},#{OPERATION_RESULT_COLUMN} = '#{errlog.to_json}'  WHERE #{OPERATION_ID_COLUMN}= #{id}"
          
          
          #errlog << {"vmname" => "TODO","status" => exception.message.to_s}
          
          #@db.execute(sql,errcode,errlog.to_json,id)
          @db.query(sql)
        end
        
        def get_queued_process_result(id)          
          check_operation_timeout
          sql="SELECT #{OPERATION_STATUS_COLUMN},#{OPERATION_RESULT_COLUMN} FROM #{OPERATION_QUEUE_TABLE_NAME} WHERE #{OPERATION_ID_COLUMN}= #{id};"          
          @db.query(sql)                    
        end
        
        def get_queued_last
          check_operation_timeout
          sql="SELECT #{OPERATION_STATUS_COLUMN},#{OPERATION_RESULT_COLUMN} FROM #{OPERATION_QUEUE_TABLE_NAME};"
          @db.query(sql)
        end
        
        
        def remove_queued_processes
          sql="DELETE FROM #{OPERATION_QUEUE_TABLE_NAME}"
          @db.query(sql)          
        end

        def are_boxes_queued
           result=@db.query("SELECT * FROM #{DOWNLOAD_BOX_TABLE} WHERE #{DOWNLOAD_STATUS_COLUMN} = #{DOWNLOAD_STOP}")

           result.size!=0

        end
        
        def start_box_download

        	result=@db.query("SELECT * FROM #{DOWNLOAD_BOX_TABLE} WHERE #{DOWNLOAD_STATUS_COLUMN} = #{DOWNLOAD_STOP}")                   	


        	id_next=result.first["id"]


        	sql="UPDATE #{DOWNLOAD_BOX_TABLE} SET  
        			#{DOWNLOAD_PROGRESS_COLUMN}='0%',
        			#{DOWNLOAD_REMAINING_COLUMN}='--:--:--',
        			#{DOWNLOAD_STATUS_COLUMN}=#{DOWNLOAD_START} 
        			WHERE #{DOWNLOAD_ID_COLUMN}=#{id_next}"

            @db.query(sql)          

            id_next	
        end

        def add_box_download_info(box_name,box_url)           	
        	sql="INSERT INTO #{DOWNLOAD_BOX_TABLE}(#{DOWNLOAD_BOX_COLUMN},#{DOWNLOAD_URL_COLUMN},#{DOWNLOAD_PROGRESS_COLUMN},#{DOWNLOAD_REMAINING_COLUMN},#{DOWNLOAD_STATUS_COLUMN}) VALUES ('#{box_name}','#{box_url}','WAITING','WAITING',#{DOWNLOAD_STOP})"
            @db.query(sql)                      
            
            last_id=@db.query("SELECT LAST_INSERT_ID() as last")            
            last_id.first["last"]
        end

        def is_box_downloading
        	result=@db.query("SELECT * FROM #{DOWNLOAD_BOX_TABLE} WHERE #{DOWNLOAD_STATUS_COLUMN} = #{DOWNLOAD_START}")
			return false if result.size==0	
			return true
        end

        def get_box_to_download
        	result=@db.query("SELECT * FROM #{DOWNLOAD_BOX_TABLE} WHERE #{DOWNLOAD_STATUS_COLUMN} = #{DOWNLOAD_STOP}")                   	
        	
        	((result.size==0)?nil:result.first)
        		

        	#id_next=result.first["id"]
        	#id_next
        end

        def get_box_download        	        	
        	sql="SELECT * FROM #{DOWNLOAD_BOX_TABLE}"
        	@db.query(sql)
        end

        def delete_box_download(id)
        	sql="DELETE FROM #{DOWNLOAD_BOX_TABLE} WHERE #{DOWNLOAD_ID_COLUMN}=#{id}"
        	@db.query(sql)
        end

        def clear_box_downloads        	
        	sql="DELETE FROM #{DOWNLOAD_BOX_TABLE}"
        	@db.query(sql)
        end

        def set_box_download_error(id)
        	sql="UPDATE #{DOWNLOAD_BOX_TABLE} SET #{DOWNLOAD_STATUS_COLUMN} = #{DOWNLOAD_ERROR}, #{DOWNLOAD_PROGRESS_COLUMN} = 'ERROR',#{DOWNLOAD_REMAINING_COLUMN}='ERROR' WHERE #{DOWNLOAD_ID_COLUMN}=#{id}"
        	@db.query(sql)
        end

        def update_box_download_info(id,progress,remaining)        	
        	sql="UPDATE #{DOWNLOAD_BOX_TABLE} SET #{DOWNLOAD_PROGRESS_COLUMN}= '#{progress}',#{DOWNLOAD_REMAINING_COLUMN}= '#{remaining}' WHERE #{DOWNLOAD_ID_COLUMN}=#{id}"

        	@db.query(sql)
        end

        def add_box_uncompression(id)

        	sql="UPDATE #{DOWNLOAD_BOX_TABLE}  SET #{DOWNLOAD_PROGRESS_COLUMN}='Uncompressing',#{DOWNLOAD_REMAINING_COLUMN}='Uncompressing',#{DOWNLOAD_STATUS_COLUMN}=#{DOWNLOAD_UNCOMPRESS} WHERE #{DOWNLOAD_ID_COLUMN}=#{id}"
        	#sql="INSERT INTO #{DOWNLOAD_BOX_TABLE}(#{DOWNLOAD_BOX_COLUMN},#{DOWNLOAD_URL_COLUMN},#{DOWNLOAD_PROGRESS_COLUMN},#{DOWNLOAD_REMAINING_COLUMN},#{DOWNLOAD_STATUS_COLUMN}) VALUES ('#{box_name}','#{box_url}','Uncompressing','Uncompressing',#{DOWNLOAD_STOP})"
            #@db.execute(sql,box_name,box_url,DOWNLOAD_PROCESS)          
            @db.query(sql)          

            # last_id=@db.query("SELECT LAST_INSERT_ID() as last")            
            # last_id.first["last"]
        end

        def set_box_uncompression_error(id)
        	sql="UPDATE #{DOWNLOAD_BOX_TABLE} SET #{DOWNLOAD_STATUS_COLUMN} = #{DOWNLOAD_ERROR}, WHERE #{DOWNLOAD_ID_COLUMN}!=#{id}"
        	#@db.execute(sql,DOWNLOAD_ERROR,id)
        	@db.query(sql)
        end

        def clear_box_uncompression(id)
        	sql="DELETE FROM #{DOWNLOAD_BOX_TABLE} WHERE #{DOWNLOAD_ID_COLUMN}=#{id}"        	
        	@db.query(sql)
        end

        def self.create_config_file(dir,dbhost,dbname,dbpuser,dbppassword,dbuser='',dbpassword='')
        	config = Hash.new
        	config[CONFIG_DBHOSTNAME]=dbhost
        	config[CONFIG_DBNAME]=dbname
        	config[CONFIG_DBUSER]=dbpuser
        	config[CONFIG_DBPASSWORD]=dbppassword        	
        	
        	File.open(dir.to_s + "/config.yml", 'w') {|f| f.write config.to_yaml } 
        end

        def self.delete_config_file(data_dir)
        	File.delete(data_dir.to_s + "/config.yml") if DBManager.check_config_file(data_dir)
        end

        def self.check_config_file(data_dir)
        	File.file?(data_dir.to_s + "/config.yml")
        end


        def close_db_connection
			@db.close
		end


		private

		def check_operation_timeout
			sql="SELECT #{OPERATION_ID_COLUMN},#{OPERATION_TIME_COLUMN} from #{OPERATION_QUEUE_TABLE_NAME} WHERE #{OPERATION_STATUS_COLUMN}= #{PROCESS_IN_PROGRESS}"
			ops=@db.query(sql)			
			rexception=RestException.new(504,"OPERATION CANCELLED BY TIMEOUT") 

			tnow=Time.now.to_i
			ops.each do |entry|
				#if timeout update db
				if (tnow > (entry["operation_time"] + OPERATION_TIMEOUT))
					set_queued_process_error(entry["operation_id"],rexception)          
				end
			end
		end

		OPERATION_TIMEOUT = 600 #In second (10 minutes)
		PROCESS_IN_PROGRESS = 100;
		PROCESS_SUCCESS = 200;
		PROCESS_ERROR = 500;

		BACKUP_TABLE_NAME='node_table'
		BACKUP_DATE_COLUMN = 'date'
		BACKUP_VM_NAME_COLUMN = 'vm_name'
		BACKUP_STATUS_COLUMN = 'backup_status'
		PASSWORD_TABLE = 'node_password_table'
		PASSWORD_COLUMN = 'node_password'
		DEFAULT_NODE_PASSWORD = 'catedrasaesumu'



		OPERATION_QUEUE_TABLE_NAME='operation_queue_table'
		OPERATION_CMD_COLUMN = 'operation_cmd'
		OPERATION_STATUS_COLUMN = 'operation_status'
		OPERATION_RESULT_COLUMN = 'operation_result'
		OPERATION_ID_COLUMN = 'operation_id'
		OPERATION_DATE_COLUMN = 'operation_date'				
		OPERATION_TIME_COLUMN = 'operation_time'

		DOWNLOAD_BOX_TABLE = 'download_box_table'
		DOWNLOAD_ID_COLUMN = 'id'
		DOWNLOAD_BOX_COLUMN = 'box_name'
		DOWNLOAD_URL_COLUMN = 'box_url'
		DOWNLOAD_STATUS_COLUMN = 'download_status'		
		DOWNLOAD_PROGRESS_COLUMN = 'download_progress'
		DOWNLOAD_REMAINING_COLUMN = 'download_remaining'
		CONFIG_DBUSER = 'dbuser'
		CONFIG_DBPASSWORD = 'dbpassword'
		CONFIG_DBHOSTNAME = 'dbhostname'
		CONFIG_DBNAME = 'dbname'




		def check_database(data_dir)					

			begin

				raise "The config file \""+data_dir.to_s + "/config.yml"+"\" doesn't exist" if !File.file?(data_dir.to_s + "/config.yml")
			
				config = YAML.load_file(data_dir.to_s + "/config.yml")
				
				raise 'Invalid configuration file' if (!config.has_key?(CONFIG_DBUSER) || 
														!config.has_key?(CONFIG_DBPASSWORD) || 
														!config.has_key?(CONFIG_DBHOSTNAME)
														!config.has_key?(CONFIG_DBNAME))
									
			end

			
			db =Mysql2::Client.new(:host => config[CONFIG_DBHOSTNAME], 
									:username => config[CONFIG_DBUSER], 
									:password => config[CONFIG_DBPASSWORD],
									:flags => Mysql2::Client::MULTI_STATEMENTS)

			#Checking if database exists
			results = db.query("SHOW DATABASES LIKE '"+config[CONFIG_DBNAME]+"'")
			
			if (results.size==0)
				results = db.query("CREATE DATABASE "+config[CONFIG_DBNAME])
			end
			
			db.query("use "+config[CONFIG_DBNAME])
			
			db.query("CREATE TABLE IF NOT EXISTS `#{BACKUP_TABLE_NAME}` (
			  `#{BACKUP_DATE_COLUMN}` text NOT NULL,
			  `#{BACKUP_VM_NAME_COLUMN}` varchar(255) NOT NULL,
			  `#{BACKUP_STATUS_COLUMN}` text NOT NULL,
			  PRIMARY KEY (`#{BACKUP_VM_NAME_COLUMN}`)
			) ENGINE=InnoDB DEFAULT CHARSET=utf8;")
			
			
			db.query("CREATE TABLE IF NOT EXISTS `#{DOWNLOAD_BOX_TABLE}` (
			  `#{DOWNLOAD_ID_COLUMN}` int(11) NOT NULL AUTO_INCREMENT,
			  `#{DOWNLOAD_BOX_COLUMN}` varchar(128) NOT NULL,
			  `#{DOWNLOAD_URL_COLUMN}` text NOT NULL,
			  `#{DOWNLOAD_PROGRESS_COLUMN}` VARCHAR(10),
			  `#{DOWNLOAD_STATUS_COLUMN}` int(11) NOT NULL,
			  `#{DOWNLOAD_REMAINING_COLUMN}` VARCHAR(10),			  		  
			  PRIMARY KEY (`#{DOWNLOAD_ID_COLUMN}`)
			) ENGINE=InnoDB DEFAULT CHARSET=utf8;")


			db.query("CREATE TABLE IF NOT EXISTS `#{PASSWORD_TABLE}` (
			  `#{PASSWORD_COLUMN}` varchar(128) NOT NULL,					  
			  PRIMARY KEY (`#{PASSWORD_COLUMN}`)
			) ENGINE=InnoDB DEFAULT CHARSET=utf8;")

			results=db.query("SELECT * from #{PASSWORD_TABLE}")

			if (results.size==0)				
				db.query("INSERT INTO #{PASSWORD_TABLE} VALUES (\"#{DEFAULT_NODE_PASSWORD}\");");            
			end

			db.query("CREATE TABLE IF NOT EXISTS `#{OPERATION_QUEUE_TABLE_NAME}` (
			  `#{OPERATION_ID_COLUMN}` int(11) NOT NULL AUTO_INCREMENT,
			  `#{OPERATION_DATE_COLUMN}` text NOT NULL,
			  `#{OPERATION_TIME_COLUMN}` int(11) NOT NULL,
			  `#{OPERATION_STATUS_COLUMN}` int(11) NOT NULL,
			  `#{OPERATION_RESULT_COLUMN}` text NOT NULL,					  
			  PRIMARY KEY (`#{OPERATION_ID_COLUMN}`)
			) ENGINE=InnoDB DEFAULT CHARSET=utf8;")					
			
			
			db
			
		end
						
	end
end
end
end
