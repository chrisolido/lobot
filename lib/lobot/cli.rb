require "thor"
require "lobot/config"
require "lobot/port_checker"
require "lobot/sobo"
require "pp"

module Lobot
  class CLI < Thor
    desc "ssh", "SSH into Lobot"
    def ssh
      exec("ssh -i #{lobot_config.server_ssh_key} ubuntu@#{lobot_config.master} -p #{lobot_config.ssh_port}")
    end

    desc "open", "Open a browser to Lobot"
    def open
      exec("open https://#{lobot_config.basic_auth_user}:#{lobot_config.basic_auth_password}@#{lobot_config.master}/")
    end

    desc "create_vagrant", "Create a new Lobot server using Vagrant"
    def create_vagrant
      spawn_env = {"LOBOT_SSH_KEY" => File.expand_path("#{lobot_config.server_ssh_key}.pub"),
                   "VAGRANT_HOME" => File.expand_path("~")}
      spawn_options = {chdir: lobot_root_path}

      pid = Process.spawn(spawn_env, "vagrant up", spawn_options)
      Process.wait(pid)

      vagrant_ip = "192.168.33.10"

      puts "Writing ip address for vagrant: #{vagrant_ip}"
      lobot_config.master = vagrant_ip
      lobot_config.save
    end

    desc "config", "Dumps all configuration data for Lobot"
    def config
      pp lobot_config.to_hash
    end

    desc "bootstrap", "Configures Lobot's master node"
    def bootstrap
      sync_bootstrap_script
      Net::SSH.start(master_server.ip, "ubuntu", keys: [master_server.key], timeout: 10000) do |ssh|
        ssh.exec("bash -l script/bootstrap_server.sh")
      end
    rescue Errno::ECONNRESET
      sleep 1
    end

    desc "chef", "Uploads chef recipes and runs them"
    def chef
      sync_chef_recipes
      upload_soloist
      Net::SSH.start(master_server.ip, "ubuntu", keys: [master_server.key], timeout: 10000) do |ssh|
        ssh.exec("bash -l -c 'rvm use 1.9.3; gem list | grep soloist || gem install --no-ri --no-rdoc soloist; soloist'")
      end
    rescue Errno::ECONNRESET
      sleep 1
    end

    no_tasks do
      def master_server
        Sobo::Server.new(lobot_config.master, lobot_config.server_ssh_key)
      end

      def lobot_config
        @lobot_config ||= Lobot::Config.from_file(lobot_config_path)
      end

      def sync_bootstrap_script
        master_server.upload(File.join(lobot_root_path, "script/"), "script/")
      end

      def sync_chef_recipes
        master_server.upload(File.join(lobot_root_path, "chef/"), "chef/")
      end

      def upload_soloist
        Tempfile.open("lobot-soloistrc") do |file|
          file.write(YAML.dump(lobot_config.soloistrc))
          file.close
          master_server.upload(file.path, "soloistrc")
        end
      end
    end

    private
    def lobot_root_path
      File.expand_path('../../..', __FILE__)
    end

    def lobot_config_path
      File.expand_path("config/lobot.yml", Dir.pwd)
    end
  end
end