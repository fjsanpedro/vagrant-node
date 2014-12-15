vagrant-node
============

This plugin allows you to set a computer with a virtual environment, configured with Vagrant, to be controlled and managed remotely. The remote machine must have installed the controller plugin, [Vagrant-NodeMaster](https://github.com/fjsanpedro/vagrant-nodemaster/tree/master/lib/vagrant-nodemaster).

With this plugin installed, the Vagrant environment can perform requests, that you usually can execute locally, but commanded by a remote computer. This service is provided through a REST API that this plugin exposes.

This plugin has been developed in the context of the [Catedra SAES](http://www.catedrasaes.org) of the University of Murcia(Spain).

##Installation
Requires Vagrant 1.2 and  MySql Server

```bash
$ vagrant plugin install vagrant-node
```

##Usage
In order to start the service provided by *vagrant-node* do:

```bash
$ vagrant nodeserver start [port]
```

Port parameter is optional, its default value is 3333. At the first start, you will be prompted to set a password for that node.



If you want to stop the service just do the following:

```bash
$ vagrant nodeserver stop
```

If you want to change the node password just execute:

```bash
$ vagrant nodeserver passwd
```




