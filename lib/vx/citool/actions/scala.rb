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
          Succ.new(0, "Scala install was successfuly completed")

        when 'sbt:update'
          re = nil
          if File.directory?('project') || File.exists?('build.sbt')
            re = invoke_shell "sbt ++#{ENV['SCALA_VERSION']} update"
            return re unless re.success?
          end

          re || Succ.new(0, "sbt tasks was successfuly processed")

        when 'sbt:test'
          if File.directory?('project') || File.exists?('build.sbt')
            invoke_shell "sbt ++#{ENV['SCALA_VERSION']} test"
          else
            NoTests.new("Cannot found the sbt configuration, no ./projects directory and no ./build.sbt file.")
          end
        end

      end
    end

  end
end
