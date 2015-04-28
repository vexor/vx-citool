module Vx
  module Citool
    module Env
      include Citool::Log
      extend  self

      DEFAULT_ENV_FILE = "/home/vexor/.my_login"

      def normalize(value)
        value.to_s.gsub(/\${([^}]+)}/) do |re|
          if $1 == "PWD"
            Dir.pwd
          else
            ENV[$1]
          end
        end
      end

      def persist_var!(key, value, opts = {})
        v = value.chomp
        ENV[key] = v
        persist_arbitrary!("export #{key}=\"#{v}\"", opts)
      end

      def persist_arbitrary!(val, opts = {})
        file = init_file(opts)
        file.puts val
        file.close
      end

      def export!(key, value, opts = {})
        var     = Var.new(key, value)
        log     = opts[:log] != false

        Actions.invoke_shell(var.export_value, hidden: true).tap do |r|
          if r.success?
            log && log_command(var.log_value)
          end
        end
      end

      def set_default_file(file)
        remove_const :DEFAULT_ENV_FILE
        const_set :DEFAULT_ENV_FILE, file
      end

      private

      def init_file(opts)
        file = opts[:file] || DEFAULT_ENV_FILE

        if file.is_a?(String)
          File.open(file, "a")
        elsif file.respond_to?(:puts)
          file
        elsif file == :tempfile
          Tempfile.new("tmp")
        else
          raise "opts[:file] should be a string, IO object or :tempfile"
        end
      end
    end
  end
end
