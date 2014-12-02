require 'pty'

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

        log_command(title) unless hidden
        command = command.gsub(/(\\)?\"/, '\"')
        cmd = %{env TERM=ansi COLUMNS=63 LINES=21 /bin/sh -c "#{command}"}

        pid    = nil
        status = nil

        pwd = chdir || Dir.pwd

        pwd = File.expand_path(pwd)
        captured_output = ""

        Dir.chdir(pwd) do
          ::PTY.spawn(cmd) do |r, w, p|
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

            pid = p
            _, status = ::Process.wait2(pid)
          end
        end

        exit_code = status.exitstatus

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
