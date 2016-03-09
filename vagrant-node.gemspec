# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)



require 'vagrant-node/version'

Gem::Specification.new do |spec|
  spec.name          = "vagrant-node"
  spec.version       = Vagrant::Node::VERSION
  spec.authors       = ["Francisco Javier Lopez de San Pedro"]
  spec.email         = ["fjsanpedro@gmail.com"]
  spec.description   = "This Vagrant plugin allows you to configure a vm environment as a node in a client/server infraestructure. See also vagrant-nodemaster"
  spec.summary       = "This plugin allows you to set a computer with a virtual environment configured with Vagrant to be controlled and managed remotely. The remote machine must have installed the controller plugin, Vagrant-NodeMaster.
With this plugin installed the Vagrant environment can perform requests, that you usually can execute locally, but commanded by a remote computer.

This plugin has been developed in the context of the Catedra SAES of the University of Murcia(Spain)."

  spec.homepage      = "http://www.catedrasaes.org"
  spec.license       = "GNU"

  spec.rubyforge_project = "vagrant-node"

  spec.add_dependency "sinatra"  
  spec.add_dependency "json"
  spec.add_dependency "rack"
  #IMPORTANT Mysql DEV libraries must be installed on system
  spec.add_dependency "mysql2", '~> 0.3.11'  
  spec.add_dependency "usagewatch"  
  spec.add_dependency "facter"  
  # spec.add_dependency "rubyzip", '< 1.0.0'
  # spec.add_dependency "sqlite3"
  spec.add_dependency "ruby2ruby", "~> 2.0.6"
  spec.add_dependency "ruby_parser", "~> 3.2.2"
  spec.add_dependency "sys-cpu"

  spec.add_dependency "rubyzip", '>= 1.0.0'
  spec.add_dependency "zip-zip"
  
   
  
  #spec.add_dependency "sambal"
  #spec.add_dependency "rexml"

  #spec.files         = `git ls-files`.split($/)
  spec.files         = `git ls-files`.split("\n")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end


