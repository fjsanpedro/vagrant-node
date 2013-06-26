vagrant-node
============

This plugin allows you to set a computer with a virtual environment configured with Vagrant to be controlled and managed remotely. The remote machine must have installed the controller plugin, [Vagrant-NodeMaster](https://github.com/fjsanpedro/vagrant-nodemaster/tree/master/lib/vagrant-nodemaster).

With this plugin installed the Vagrant environment can perform requests, that you usually can execute locally, but commanded by a remote computer. This service is provided through a REST API that this plugin exposes.

This plugin has been developed in the context of the [Catedra SAES](http://www.catedrasaes.org) of the University of Murcia(Spain).

##Installation
Requires Vagrant 1.2 and libsqlite3-dev

```bash
$ vagrant plugin install vagrant-node
```

##Usage
In order to start the service provided by *vagrant-node* do:

```bash
$ vagrant nodeserver start [port]
```

Port parameter is optional, its default value is 3333.

If you want to stop the service just do the follogin:

```bash
$ vagrant nodeserver stop
```


## Important:
**The main lack of this version is that there is no type of authentication mechanism. Be carefull when you use it in a public infraestructure.**

## To-Do:
* Because the plugin is still under development, there are some comments and *puts* sentences that will be removed in latter versions.
* An enhanced and more rich error mechanism between the local machine and remote controller
* Lots of things...

