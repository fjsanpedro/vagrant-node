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
  spec.summary       = "ESCRIBIR SUMMARY"
  spec.homepage      = "http://www.catedrasaes.org"
  spec.license       = "GNU"

  spec.rubyforge_project = "vagrant-node"

  spec.add_dependency "sinatra"
  spec.add_dependency "json"
  spec.add_dependency "rack"
  spec.add_dependency "rubyzip"
  spec.add_dependency "sqlite3"
  #spec.add_dependency "sambal"
  #spec.add_dependency "rexml"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
