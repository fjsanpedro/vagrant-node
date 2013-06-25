require 'rubygems'
require 'sinatra'
require 'json'
require 'rack'
require 'vagrant-node/clientcontroller'
require 'vagrant-node/apidesc'


require 'pp'
module Vagrant
	module Node
		module ServerAPI
			
			class API < Sinatra::Base
				include RestRoutes 
				before do 
  					content_type :json
				end
				
				
				#UPLOAD A FILE
#				post '/' do
				#  tempfile = params['file'][:tempfile]
				#  filename = params['file'][:filename]
				#  File.copy(tempfile.path, "./files/#{filename}")
				#  redirect '/'
				#end		
				
				
#				before '/admin/*' do
#  				authenticate!
#				end
				
			######### FIXME DELETE #####################			
			get '/' do
					"Hello World"
			end		
			
			###############################################
				
			get RouteManager.box_list_route	do				
				ClientController.listboxes.to_json
			end

			delete RouteManager.box_delete_route do					
				handle_response_result(ClientController.box_delete(params[:box],params[:provider]))
			end				
			
			post RouteManager.box_add_route do					
				handle_response_result(ClientController.box_add(params[:box],params[:url]))
			end
			
				
								
			get RouteManager.vm_status_all_route do
				handle_response_result(ClientController.vm_status(nil))
			end
			
				

			get RouteManager.vm_status_route do
				handle_response_result(ClientController.vm_status(params[:vm]))
			end
			
			#accept :vmname as paramter. This parameter
			#could be empty
			post RouteManager.vm_up_route do
				handle_response_result(ClientController.vm_up(params[:vmname]))
			end
				
			#accept :vmname and :force as paramters
			post RouteManager.vm_halt_route do
				handle_response_result(ClientController.vm_halt(params[:vmname],params[:force]))
			end
				
			#accept :vmname as paramter. This parameter
			#could be empty
			post RouteManager.vm_destroy_route do
				handle_response_result(ClientController.vm_confirmed_destroy(params[:vmname]))
			end
				
			#accept :vmname as paramter. This parameter
			#could be empty
			post RouteManager.vm_suspend_route do
				handle_response_result(ClientController.vm_suspend(params[:vmname]))
			end
				
			#accept :vmname as paramter. This parameter
			#could be empty
			post RouteManager.vm_resume_route do					
				handle_response_result(ClientController.vm_resume(params[:vmname]))
			end
			
			post RouteManager.vm_provision_route do
				handle_response_result(ClientController.vm_provision(params[:vmname]))
			end
				
				
				
			get RouteManager.vm_sshconfig_route do				
				handle_response_result(ClientController.vm_ssh_config(params[:vm]))
			end
				
			get RouteManager.snapshots_all_route do
				handle_response_result(ClientController.vm_snapshots(nil))
			end
			
					
			
			get RouteManager.vm_snapshots_route do
				handle_response_result(ClientController.vm_snapshots(params[:vm]))
			end
			
			get RouteManager.vm_snapshot_take_route do														
				result=ClientController.vm_snapshot_take_file(params[:vmname])
				
					
				send_file "#{result[1]}", :filename => result[1], 
									:type => 'Application/octet-stream' if result[0]==200 && params[:download]="true"
				
				status result[0]
					
			end
			
						
			post RouteManager.vm_snapshot_take_route do
					handle_response_result(ClientController.vm_snapshot_take(params[:vmname],params[:name],params[:desc]))
			end
			
			
			post RouteManager.vm_snapshot_restore_route do
					handle_response_result(ClientController.vm_snapshot_restore(params[:vmname],params[:snapid]))
			end
			
			
			get RouteManager.vm_backup_log_route do
				handle_response_result(ClientController.backup_log(params[:vm]))
			end
			
				

			get RouteManager.node_backup_log_route do
				handle_response_result(ClientController.backup_log(nil))
			end
			
				
			private
			def handle_response_result(result)														
					if (!result)											
						status 500
					elsif (result.empty?)												
						status 404
					end					
					result.to_json
			end
				
			end
		end
	end
end
