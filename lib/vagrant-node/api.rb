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
#  					pp request
				end
				
				######### FIXME DELETE #####################			
				get '/' do
  				  "Hello World"
				end
				
				get '/id' do
					"ID SOLAMENTE"
				end
				
				get '/id/:id' do
					"QUIERES ALGO DE LA ID #{params[:id]}"
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
				
				
#				get '/api/vm/status' do								
				get RouteManager.vm_status_all_route do
#					result=ClientController.vm_status(nil)
#					if (!result)
#						status 500
#					end
#					result.to_json
					handle_response_result(ClientController.vm_status(nil))
				end
				
				
#				get '/api/vm/:vm/status' do
				get RouteManager.vm_status_route do
#					result=ClientController.vm_status(params[:vm])
#					if (!result)
#						status 500
#					elsif (result.empty?)						
#						status 404
#					end
#					result.to_json
					handle_response_result(ClientController.vm_status(params[:vm]))
				end
				
				#accept :vmname as paramter. This parameter
				#could be empty
#				post '/api/vm/up' do
				post RouteManager.vm_up_route do
#					machines=ClientController.vm_up(params[:vmname])
#					if (!machines)
#						status 500
#					elsif (machines.empty?)
#						status 404
#					end					
#					machines.to_json	
					handle_response_result(ClientController.vm_up(params[:vmname]))
				end
				
				#accept :vmname and :force as paramters
#				post '/api/vm/halt' do
				post RouteManager.vm_halt_route do
#					machines=ClientController.vm_halt(params[:vmname],params[:force])
#					if (!machines)
#						status 500
#					elsif (machines.empty?)
#						status 404
#					end					
#					machines.to_json	
					handle_response_result(ClientController.vm_halt(params[:vmname],params[:force]))
				end
				
				#accept :vmname as paramter. This parameter
				#could be empty
#				post '/api/vm/destroy' do
				post RouteManager.vm_destroy_route do
#					machines=ClientController.vm_confirmed_destroy(params[:vmname])
#					if (!machines)
#						status 500
#					elsif (machines.empty?)
#						status 404
#					end		
#					machines.to_json
					handle_response_result(ClientController.vm_confirmed_destroy(params[:vmname]))
				end
				
				#accept :vmname as paramter. This parameter
				#could be empty
#				post '/api/vm/up' do
				post RouteManager.vm_suspend_route do
#					machines=ClientController.vm_suspend(params[:vmname])
#					if (!machines)
#						status 500
#					elsif (machines.empty?)
#						status 404
#					end					
#					machines.to_json	
					
					handle_response_result(ClientController.vm_suspend(params[:vmname]))
				end
				
				#accept :vmname as paramter. This parameter
				#could be empty
#				post '/api/vm/up' do
				post RouteManager.vm_resume_route do
#					machines=ClientController.vm_resume(params[:vmname])
#					if (!machines)
#						status 500
#					elsif (machines.empty?)
#						status 404
#					end					
#					machines.to_json	
					
					handle_response_result(ClientController.vm_resume(params[:vmname]))
				end
				
				post RouteManager.vm_provision_route do
#					machines=ClientController.vm_provision(params[:vmname])
#					if (!machines)
#						status 500
#					elsif (machines.empty?)
#						status 404
#					end					
#					machines.to_json	
					handle_response_result(ClientController.vm_provision(params[:vmname]))
				end
				
				
				#get '/api/vm/:vm/sshconfig' do
				get RouteManager.vm_sshconfig_route do
#					result=ClientController.vm_ssh_config(params[:vm])
#					if (!result)
#						status 500
#					elsif (result.empty?)						
#						status 404
#					end										
#					result.to_json
					handle_response_result(ClientController.vm_ssh_config(params[:vm]))
			end
				
			get RouteManager.snapshots_all_route do
				handle_response_result(ClientController.vm_snapshots(nil))
			end
			
					
			
			get RouteManager.vm_snapshots_route do
				handle_response_result(ClientController.vm_snapshots(params[:vm]))
			end
			
			post RouteManager.vm_snapshot_take_route do
					handle_response_result(ClientController.vm_snapshot_take(params[:vmname],params[:name],params[:desc]))
			end
			
			
			post RouteManager.vm_snapshot_restore_route do
					handle_response_result(ClientController.vm_snapshot_restore(params[:vmname],params[:snapid]))
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
