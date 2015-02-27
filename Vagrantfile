# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "chef-VAGRANTSLASH-centos-6.5"

  config.vm.define :zabbix do |zabbix_config|
      zabbix_config.vm.host_name = "zabbix"
      zabbix_config.vm.network "private_network", ip:"192.168.100.10"
      config.vm.provider :virtualbox do |vb|
          vb.customize ["modifyvm", :id, "--memory", "256"]
          vb.customize ["modifyvm", :id, "--cpus", "1"]
      end
  end

  config.vm.define :web do |web_config|
      web_config.vm.host_name = "web"
      web_config.vm.network "private_network", ip:"192.168.100.20"
      config.vm.provider :virtualbox do |vb|
          vb.customize ["modifyvm", :id, "--memory", "256"]
          vb.customize ["modifyvm", :id, "--cpus", "1"]
      end
  end

  config.vm.define :db do |db_config|
      db_config.vm.host_name = "db"
      db_config.vm.network "private_network", ip:"192.168.100.30"
      config.vm.provider :virtualbox do |vb|
          vb.customize ["modifyvm", :id, "--memory", "512"]
          vb.customize ["modifyvm", :id, "--cpus", "2"]
      end
  end
end
