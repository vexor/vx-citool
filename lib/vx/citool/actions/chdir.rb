module Vx
  module Citool

    module Actions
      def invoke_chdir(args)
        args = extract_keys(args)
        log_command "cd #{args[:rest]}"
        dest = File.expand_path(args[:rest])
        Dir.chdir(dest)

        Succ.new(0,  "The command 'cd #{args[:rest]}' exited with code 0")
      end
    end

  end
end
