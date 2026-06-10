# -*- mode: ruby -*-
# vi: set ft=ruby :

env = {}
File.readlines('.env').each do |line|
  next if line.strip.start_with?('#') || line.strip.empty?
  key, val = line.strip.split('=', 2)
  env[key] = val
end

Vagrant.configure("2") do |config|
  config.vm.box = "debian/bookworm64"
  config.vm.box_check_update = false

  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope = :box
  end

  # --- DB ---
  config.vm.define "db", primary: true do |node|
    node.vm.hostname = "db"
    node.vm.network "private_network", ip: env["DB_IP"]
    node.vm.provider "virtualbox" do |vb|
      vb.name   = "redes2-db"
      vb.memory = 512
      vb.cpus   = 1
      vb.gui    = false
    end
    node.vm.provision "shell", path: "provision/common.sh"
    node.vm.provision "shell", path: "provision/db.sh", env: {
      "DB_NAME" => env["DB_NAME"],
      "DB_USER" => env["DB_USER"],
      "DB_PASS" => env["DB_PASS"],
    }
  end

  # --- Moodle 1 (primary + NFS server) ---
  config.vm.define "moodle1" do |node|
    node.vm.hostname = "moodle1"
    node.vm.network "private_network", ip: env["MOODLE1_IP"]
    node.vm.provider "virtualbox" do |vb|
      vb.name   = "redes2-moodle1"
      vb.memory = 1024
      vb.cpus   = 1
      vb.gui    = false
    end
    node.vm.provision "shell", path: "provision/common.sh"
    node.vm.provision "shell", path: "provision/moodledata-server.sh"
    node.vm.provision "shell", path: "provision/moodle.sh", env: {
      "DB_HOST"            => env["DB_HOST"],
      "DB_NAME"            => env["DB_NAME"],
      "DB_USER"            => env["DB_USER"],
      "DB_PASS"            => env["DB_PASS"],
      "MOODLE_VERSION"     => env["MOODLE_VERSION"],
      "MOODLE_HOST_IP"     => env["MOODLE1_IP"],
      "MOODLE_ADMIN_USER"  => env["MOODLE_ADMIN_USER"],
      "MOODLE_ADMIN_PASS"  => env["MOODLE_ADMIN_PASS"],
      "MOODLE_ADMIN_EMAIL" => env["MOODLE_ADMIN_EMAIL"],
      "MOODLE_FULLNAME"    => env["MOODLE_FULLNAME"],
      "MOODLE_SHORTNAME"   => env["MOODLE_SHORTNAME"],
      "MOODLE_LANG"        => env["MOODLE_LANG"],
      "IS_PRIMARY"         => "true",
      "MOODLE_WWWROOT"     => env["MOODLE_WWWROOT"],
    }
  end

  # --- Moodle 2 e 3 (NFS clients) ---
  { "moodle2" => env["MOODLE2_IP"],
    "moodle3" => env["MOODLE3_IP"] }.each do |name, ip|
    config.vm.define name do |node|
      node.vm.hostname = name
      node.vm.network "private_network", ip: ip
      node.vm.provider "virtualbox" do |vb|
        vb.name   = "redes2-#{name}"
        vb.memory = 1024
        vb.cpus   = 1
        vb.gui    = false
      end
      node.vm.provision "shell", path: "provision/common.sh"
      node.vm.provision "shell", path: "provision/moodledata-client.sh"
      node.vm.provision "shell", path: "provision/moodle.sh", env: {
        "DB_HOST"            => env["DB_HOST"],
        "DB_NAME"            => env["DB_NAME"],
        "DB_USER"            => env["DB_USER"],
        "DB_PASS"            => env["DB_PASS"],
        "MOODLE_VERSION"     => env["MOODLE_VERSION"],
        "MOODLE_HOST_IP"     => ip,
        "MOODLE_ADMIN_USER"  => env["MOODLE_ADMIN_USER"],
        "MOODLE_ADMIN_PASS"  => env["MOODLE_ADMIN_PASS"],
        "MOODLE_ADMIN_EMAIL" => env["MOODLE_ADMIN_EMAIL"],
        "MOODLE_FULLNAME"    => env["MOODLE_FULLNAME"],
        "MOODLE_SHORTNAME"   => env["MOODLE_SHORTNAME"],
        "MOODLE_LANG"        => env["MOODLE_LANG"],
        "IS_PRIMARY"         => "false",
        "MOODLE_WWWROOT"     => env["MOODLE_WWWROOT"],
      }
    end
  end

  # --- Proxy ---
  config.vm.define "proxy" do |node|
    node.vm.hostname = "proxy"
    node.vm.network "private_network", ip: env["PROXY_IP"]
    node.vm.network "forwarded_port", guest: 80, host: 8080
    node.vm.boot_timeout = 600
    node.vm.provider "virtualbox" do |vb|
      vb.name   = "redes2-proxy"
      vb.memory = 512
      vb.cpus   = 1
      vb.gui    = false
    end
    node.vm.provision "shell", path: "provision/common.sh"
    node.vm.provision "shell", path: "provision/proxy.sh"
  end
end
