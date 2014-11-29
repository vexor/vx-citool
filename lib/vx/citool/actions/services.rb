module Vx
  module Citool

    module Actions
      def invoke_services(args, options = {})
        args = extract_keys(args)

        services = args[:rest].strip.split(" ")

        re = nil
        services.each do |srv|
          re = invoke_shell("sudo service #{srv} start")
          return re unless re.success?
        end

        if services.any?
          re = invoke_shell "sleep 3"
          return re unless re.success?
        end

        re || Succ.new(0, "services task was successfuly completed")

      end
    end

  end
end
