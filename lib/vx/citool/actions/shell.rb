require 'pty'
require 'shellwords'

module Vx
  module Citool
    module Actions

      SHELL_ALIAS = {
        "parallel_rspec"   => File.expand_path("../../scripts/vx_parallel_rspec",   __FILE__),
        "parallel_spinach" => File.expand_path("../../scripts/vx_parallel_spinach", __FILE__)
      }

      # TODO: remove
      SHELL_IGNORED_COMMANDS = [
        'gem update bundler'
      ]

      def invoke_shell(args, options = {})

        command = nil
        chdir   = nil

        if args.is_a?(String)
          command = args
        else
          command = args["command"]
          chdir   = args["chdir"]
        end

        command = normalize_env_value(command)

        if SHELL_IGNORED_COMMANDS.include?(command)
          log_error("The command '#{command}' ignored, if you really need to do it, please contact us")
          return Succ.new(0, "The command '#{command}' exited with unknown status")
        end

        silent  = options[:silent]
        title   = options[:title] || command
        hidden  = options[:hidden]

        if found = SHELL_ALIAS[command]
          title = command
          command  = found
        end

        if command =~ /^nohup (.*)$/
          command = $1
          options[:detach] = true
        end

        log_command(title) unless hidden
        cmd = %{/bin/sh -c #{Shellwords.escape command}}

        pid    = nil
        r      = nil
        w      = nil
        status = nil

        pwd = chdir || Dir.pwd

        pwd = File.expand_path(pwd)
        captured_output = ""

        Dir.chdir(pwd) do
          if options[:detach]
            pid = ::Process.spawn(cmd, out: "nohup.log", err: "nohup.log")
            Citool.teardown do
              log_debug "kill '#{cmd}', pid #{pid}"
              begin
                Process.kill("KILL", pid)
                Process.wait(pid)
              rescue Exception
              end
            end
          else
            r, w, pid = ::PTY.spawn(cmd)
          end
        end

        unless options[:detach]
          begin
            r.sync = true
            w.close

            loop do
              rs, _, _ = IO.select([r], nil, nil, 0.1)

              if rs
                break if rs[0].eof?
                chunk = rs[0].readpartial(8192)
                if silent
                  captured_output << chunk
                else
                  print chunk
                end
              end
            end
          rescue Errno::EIO
          end
          _, status = ::Process.wait2(pid)
        end

        compute_shell_exist_code status, command, silent, captured_output, options
      end

      def compute_shell_exist_code(status, command, silent, captured_output, options)
        exit_code =
          if options[:detach]
            0
          else
            status.exitstatus
          end

        if exit_code != 0 && silent
          print captured_output
        end

        message =
          if exit_code
            "The command '#{command}' exited with code #{exit_code}"
          else
            "The command '#{command}' exited with unknown status"
          end

        if exit_code == 0
          Succ.new(0, message, captured_output)
        else
          Fail.new(exit_code, message, captured_output)
        end

      end

    end
  end
end
