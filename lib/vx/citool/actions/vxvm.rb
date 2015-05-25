module Vx
  module Citool
    module Actions

      def invoke_vxvm(args, options = {})
        vxvm = File.expand_path("../../scripts/vxvm", __FILE__)

        re = invoke_shell("#{vxvm} install #{args}", silent: true, title: "vxvm install #{args}")
        return re unless re.success?

        invoke_shell_source(re.data.strip)
      end
    end
  end
end
