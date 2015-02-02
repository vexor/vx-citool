require 'fileutils'
require 'socket'
require 'timeout'

module Vx
  module Citool
    module Actions

      def invoke_ssh_agent(args, options = {} )
        ssh_dir   = options[:ssh_dir] || File.expand_path("~/.ssh")
        keys      = args["key"]

        ssh_keys =
          if keys.is_a?(String) && keys.match(/\A\$(.+)\Z/)
            options[:vars][$1]
          else
            keys
          end

        ssh_keys  = [ssh_keys] unless ssh_keys.is_a?(Array)

        file_name = ->(index){ "#{ssh_dir}/id#{index}_rsa"}

        agent_sock = "#{ssh_dir}/agent.sock"

        log_debug "create ssh dir"
        FileUtils.mkdir_p ssh_dir, mode: 0700

        log_debug "create ssh key files"

        ssh_keys.each_with_index do |key, index|
          file = file_name[index]

          File.open(file, 'w') do |io|
            io.write key
          end

          FileUtils.chmod 0600, file
        end

        log_debug "write ssh_config file"

        File.open("#{ssh_dir}/config", 'w') do |io|
          io.write "Host *\n"
          io.write "  ForwardAgent yes\n"
          io.write "  UserKnownHostsFile /dev/null\n"
          io.write "  StrictHostKeyChecking no\n"
          io.write "  LogLevel INFO"
        end

        log_debug "start ssh agent at #{agent_sock}"
        FileUtils.rm_f agent_sock

        cmd = "ssh-agent -d -a #{agent_sock}"
        pid = Process.spawn(cmd, out: "/dev/null", err: "/dev/null")

        ENV['SSH_AUTH_SOCK'] = agent_sock

        Citool.teardown do
          log_debug "kill ssh-agent, pid #{pid}"
          Process.kill("KILL", pid)
          Process.wait(pid)
          FileUtils.rm_f agent_sock
        end

        # wait agent
        begin
          Timeout.timeout(5) do
            loop do
              sleep 0.1
              begin
                s = ::UNIXSocket.new(agent_sock)
                unless s.nil?
                  s.close
                  break
                end
              rescue Errno::ENOENT, Errno::ECONNREFUSED, Errno::EBADF
              end
            end
          end
        rescue Timeout::TimeoutError
        end

        re = ssh_keys.map.with_index do |_, index|
          file = file_name[index]
          invoke_shell("ssh-add #{file}", silent: true, title: "~/.ssh/id#{index}_rsa")
        end

        return re unless re.all?(&:success?)

        Succ.new(0, "Ssh Agent was successfuly started", pid: pid)
      end
    end
  end
end
