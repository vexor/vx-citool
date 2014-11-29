module Vx
  module Citool
    module Actions

      def invoke_vxvm(args, options = {})
        args = extract_keys(args, :lang, :version)

        vxvm = File.expand_path("../../scripts/vxvm", __FILE__)
        params = "#{args[:lang]} #{args[:version]}"

        re = invoke_shell("#{vxvm} install #{params}", silent: true, title: "vxvm install #{params}", silent: true)
        return re unless re.success?

        source = re.data.strip

        re = invoke_shell(". #{source} ; env", silent: true)
        return re unless re.success?

        re.data.lines.each do |line|
          line  = line.strip.split("=")
          key   = line.shift
          value = line.join("=")
          ENV[key] = value
        end

        re
      end

    end
  end
end
