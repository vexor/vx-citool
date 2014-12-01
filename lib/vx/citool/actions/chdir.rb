module Vx
  module Citool

    module Actions
      def invoke_chdir(args, options = {})
        log_command "cd #{args}"
        dest = normalize_env_value(args)
        dest = File.expand_path(dest)
        Dir.chdir(dest)

        Succ.new(0,  "The command 'cd #{args}' exited with code 0")
      end
    end

  end
end
