require 'sqlite3'

module Vagrant
	module Node
		module DB
			class DBManager
				
				def initialize(data_dir)
					@db=check_database(data_dir)
				end
				
				def get_backup_log_entries(vmname)
					sql="SELECT * FROM #{BACKUP_TABLE_NAME}"
					sql = sql + " WHERE #{BACKUP_VM_NAME_COLUMN} = \"#{vmname}\"" if vmname					
					
					#return rows
					@db.execute(sql)
					
				end
				
				def add_backup_log_entry(date,vmname,status)
					sql="INSERT INTO #{BACKUP_TABLE_NAME} VALUES ( ? , ? , ? )"					
					@db.execute(sql,date,vmname,status)
				end
				
				def update_backup_log_entry(date,vmname,status)					
					sql="UPDATE #{BACKUP_TABLE_NAME} SET #{BACKUP_STATUS_COLUMN} = ? WHERE #{BACKUP_DATE_COLUMN}= ? AND #{BACKUP_VM_NAME_COLUMN}= ?"
					@db.execute(sql,status,date,vmname)					
				end
	 				

				private
			
				BACKUP_TABLE_NAME='node_table'
				BACKUP_DATE_COLUMN = 'date'
				BACKUP_VM_NAME_COLUMN = 'vm_name'
				BACKUP_STATUS_COLUMN = 'backup_status'
				
				def check_database(data_dir)					
					#Creates and/or open the database
					
					db = SQLite3::Database.new( data_dir.to_s + "/node.db" )
									
					if db.execute("SELECT name FROM sqlite_master 
											 WHERE type='table' AND name='#{BACKUP_TABLE_NAME}';").length==0						
						db.execute( "create table '#{BACKUP_TABLE_NAME}' (#{BACKUP_DATE_COLUMN} TEXT NOT NULL, 
												 																#{BACKUP_VM_NAME_COLUMN} TEXT PRIMARY_KEY,
												 																#{BACKUP_STATUS_COLUMN} TEXT NOT NULL);" )
					end
					
					#return db
					db
					
				end
						
			end
		end
	end
end
