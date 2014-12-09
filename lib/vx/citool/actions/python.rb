module Vx
  module Citool

    module Actions

      PYTHON_VIRTUAL_ENV = "~/.virtualenv"

      def invoke_python(args, options = {})
        action = nil

        if args.is_a?(String)
          action = args
          args   = {}
        else
          action = args["action"]
        end

        case action
        when 'virtualenv'
          ve = File.expand_path PYTHON_VIRTUAL_ENV
          log_command "export VIRTUAL_ENV=#{PYTHON_VIRTUAL_ENV}"
          ENV['VIRTUAL_ENV'] = ve

          log_command "export PATH=#{PYTHON_VIRTUAL_ENV}/bin:$PATH"
          ENV['PATH'] = "#{ve}/bin:#{ENV['PATH']}"

          invoke_shell("virtualenv #{ve}", title: "virtualenv #{PYTHON_VIRTUAL_ENV}")

        when 'install'
          invoke_vxvm "python #{args["python"]}"

        when 'pip:install'
          re = nil
          pip_args = args["pip_args"]

          if File.exists?("Requirements.txt")
            re = invoke_shell "pip install -r Requirements.txt #{pip_args}"
            return re unless re.success?
          end

          if File.exists?("requirements.txt")
            re = invoke_shell "pip install -r requirements.txt #{pip_args}"
            return re unless re.success?
          end

          if File.exists?("setup.py")
            re = invoke_shell "python setup.py install"
            return re unless re.success?
          end

          re || Succ.new(0, "pip tasks was successfuly processed")

        when 'django:settings'

          re = nil
          app = File.basename(Dir.pwd)

          if File.exists?("settings.py") &&
              File.exists?("#{app}/settings/dev.py") &&
              !File.exists?("#{app}/settings/__init__.py")
            re = invoke_shell "ln -s $(pwd)/#{app}/settings/dev.py $(pwd)/#{app}/settings/__init__.py"
          end

          re || Succ.new(0, "django tasks was successfuly processed")

        when 'script'

          case
          when File.exists?("manage.py")
            invoke_shell "python manage.py test"
          when File.exists?("setup.py")
            invoke_shell "python setup.py test"
          else
            invoke_shell "nosetests"
          end

        when 'announce'
          re = invoke_shell "python --version"
          return re unless re.success?

          re = invoke_shell "pip --version"
          return re unless re.success?

          re
        end
      end
    end

  end
end
