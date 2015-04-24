module Vx
  module Citool
    module Actions

      def invoke_vxvm(args, options = {})
        vxvm = File.expand_path("../../scripts/vxvm", __FILE__)

        re = invoke_shell("#{vxvm} install #{args}", silent: true, title: "vxvm install #{args}")
        return re unless re.success?

        source = re.data.strip

        re = invoke_shell(". #{source} ; env", silent: true)
        return re unless re.success?

        re.data.lines.each do |line|
          line  = line.strip.split("=")
          key   = line.shift
          value = line.join("=")

          Env.persist_var!(key, "#{value}")
        end

        re
      end

    end
  end
end
