module Vx
  module Citool
    module Actions

      def invoke_vxvm(args, options = {})
        vxvm = File.expand_path("../../scripts/vxvm", __FILE__)

        re = invoke_shell("#{vxvm} install #{args}", silent: true, title: "vxvm install #{args}")
        return re unless re.success?

        # user = ENV['USER']
        # unless user == ""
        #   # re_chown = invoke_shell("sudo chown -R #{user} /opt/vexor/packages")
        #   re_chown = invoke_shell("sudo find /opt/vexor/packages/* | xargs chown #{user}")
        #   return re_chown unless re_chown.success?
        # end

        invoke_shell_source(re.data.strip)
      end
    end
  end
end
