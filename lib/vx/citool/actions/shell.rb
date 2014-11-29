require 'pty'

module Vx
  module Citool
    module Actions

      SHELL_ALIAS = {
        "vx_parallel_rspec"   => File.expand_path("../../scripts/vx_parallel_rspec",   __FILE__),
        "vx_parallel_spinach" => File.expand_path("../../scripts/vx_parallel_spinach", __FILE__)
      }

      def invoke_shell(args, options = {})
        args    = extract_keys(args, :chdir)
        rest    = args[:rest]
        silent  = options[:silent]
        title   = options[:title] || rest
        hidden  = options[:hidden]

        if found = SHELL_ALIAS[rest]
          title = rest
          rest  = found
        end

        log_command(title) unless hidden
        cmd = "/bin/sh -c #{Shellwords.shellescape rest}"

        pid    = nil
        status = nil

        pwd           = args[:chdir] || Dir.pwd
        pwd           = File.expand_path(pwd)
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
            "The command '#{rest}' exited with code #{exit_code}"
          else
            "The command '#{rest}' exited with unknown status"
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
