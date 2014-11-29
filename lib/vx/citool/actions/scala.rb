module Vx
  module Citool

    module Actions

      def invoke_scala(args, options = {})
        action = nil

        if args.is_a?(String)
          action = args
          args   = {}
        else
          action = args["action"]
        end

        case action
        when 'install'
          log_command "export SCALA_VERSION=#{args['scala']}"
          ENV['SCALA_VERSION'] = args['scala']

        when 'sbt:update'
          re = nil
          if File.directory?('project') || File.exists?('build.sbt')
            re = invoke_shell "sbt ++#{ENV['SCALA_VERSION']} update"
            return re unless re.success?
          end

          re || Succ.new(0, "sbt tasks was successfuly processed")

        when 'sbt:test'
          re = nil
          if File.directory?('project') || File.exists?('build.sbt')
            re = invoke_shell "sbt ++#{ENV['SCALA_VERSION']} test"
            return re unless re.success?
          end

          re || Succ.new(0, "sbt tasks was successfuly processed")
        end

      end
    end

  end
end
