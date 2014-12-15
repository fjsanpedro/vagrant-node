
require 'vagrant'

module Vagrant
	module Node
	  
	  class RestException < StandardError	    
      def initialize(code,msg)
        super(msg)
        @code = code        
      end
      def code
        @code
      end
    end	

    class VMActionException < StandardError     
      def initialize(vmname,provider,msg)
        super(msg)
        @vmname = vmname        
        @provider = provider
      end
      def vmname
        @vmname
      end

      def provider
        @provider
      end
    end 

    class ExceptionMutator < RestException
      include Vagrant::Errors
      def initialize(exception)
        if (exception.is_a?(Vagrant::Errors::VagrantError))         
          puts exception.class
          case exception               
          when BaseVMNotFound,
               BoxNotFound,
               BoxSpecifiedDoesntExist,
               MachineNotFound,
               NetworkNotFound,
               ProviderNotFound,
               VMNotFoundError,
               VagrantfileExistsError
            super(404,exception.message)
          when BoxNotSpecified,
               CLIInvalidOptions,
               CLIInvalidUsage,
               DestroyRequiresForce           
            super(400,exception.message)
          when ConfigInvalid,
               NameError,
               # ConfigValidationFailed,
               # DeprecationError,
               DownloaderFileDoesntExist,
               BoxProviderDoesntMatch,
               #BoxDownloadUnknownType,
               BoxAlreadyExists,
               ActiveMachineWithDifferentProvider,
               BoxUnpackageFailure,
               BoxUpgradeRequired, 
               BoxVerificationFailed,
               VMImportFailure               
            super(406,exception.message)           
          else
            super(500,exception.message)
          end
          
        else
          super(500,exception.message)
        end
        
      end
    end
    
	end
end


 # Otras que por ahora no veo la necesidad de incluirlas
 # , , , , 
 # , , DotfileIsDirectory, DotfileUpgradeJSONError, , 
 # DownloaderHTTPConnectReset, DownloaderHTTPConnectTimeout, DownloaderHTTPSocketError, DownloaderHTTPStatusError, 
 # EnvironmentLockedError, EnvironmentNonExistentCWD, ForwardPortAutolistEmpty, ForwardPortCollision, 
 # ForwardPortCollisionResume, GemCommandInBundler, HomeDirectoryMigrationFailed, HomeDirectoryNotAccessible, 
 # LocalDataDirectoryNotAccessible, MachineGuestNotReady, , MultiVMEnvironmentRequired, MultiVMTargetRequired, 
 # NFSHostRequired, NFSNoHostNetwork, NFSNotSupported, NetworkAdapterCollision, NetworkCollision, 
 # NetworkDHCPAlreadyAttached, NetworkNoAdapters, , NoEnvironmentError, 
 # PackageIncludeMissing, PackageOutputDirectory, PackageOutputExists, PackageRequiresDirectory,
  # PersistDotfileExists, PluginLoadError, , SCPPermissionDenied, SCPUnavailable, SSHAuthenticationFailed
  # , SSHConnectionRefused, SSHConnectionTimeout, SSHDisconnected, SSHHostDown, SSHKeyBadPermissions
  # , SSHKeyTypeNotSupported, SSHNotReady, SSHPortNotDetected, SSHUnavailable
  # , SSHUnavailableWindows, SharedFolderCreateFailed, UIExpectsTTY, UnimplementedProviderAction,
   







