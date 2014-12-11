module Vx
  module Citool

    module Actions
      def invoke_services(args, options = {})
        re = nil

        Array(args).each do |srv|
          re = invoke_shell("sudo service #{srv} start")
          return re unless re.success?
        end

        if Array(args).any?
          re = invoke_shell "sleep 3"
          return re unless re.success?
        end

        re || Succ.new(0, "services task was successfuly completed")

      end
    end

  end
end
