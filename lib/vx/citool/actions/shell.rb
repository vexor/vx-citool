require 'pty'

module Vx
  module Citool
    module Actions

      def invoke_shell(args)
        args = extract_keys(args, :chdir)
        rest = args[:rest]

        log_command(args[:rest])
        cmd = "/bin/sh -c #{Shellwords.shellescape rest}"

        pid    = nil
        status = nil

        pwd    = args[:chdir] || Dir.pwd
        pwd    = File.expand_path(pwd)
        Dir.chdir(pwd) do
          ::PTY.spawn(cmd) do |r, w, p|
            r.sync = true
            w.close

            loop do
              rs, _, _ = IO.select([r], nil, nil, 0.1)

              if rs
                break if rs[0].eof?
                print rs[0].readpartial(8192)
              end
            end

            pid = p
            _, status = ::Process.wait2(pid)
          end
        end

        exit_code = status.exitstatus

        message =
          if exit_code
            "The command '#{args[:rest]}' exited with code #{exit_code}"
          else
            "The command '#{args[:rest]}' exited with unknown status"
          end

        if exit_code == 0
          Succ.new(0, message)
        else
          Fail.new(exit_code, message)
        end
      end

    end
  end
end
