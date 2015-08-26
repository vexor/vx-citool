module Vx ; module Citool ; module Actions

  def invoke_jdk(args, options = {})
    action = nil
    if args.is_a?(String)
      action = args
      args   = {}
    else
      action = args["action"]
    end

    case action
    when 'install'
      version = args["version"] || "default"
      jdk     = File.expand_path("../../scripts/jdk", __FILE__)
      file     = "#{Dir.tmpdir}/.JAVA_HOME"

      Citool.teardown do
        File.readable?(file) && File.unlink(file)
      end

      re = invoke_shell "#{jdk} #{version} #{file}", title: "jdk use #{version}"
      return re unless re.success?

      if File.readable?(file)
        value = File.read(file)
        Env.persist_var!('JAVA_HOME', value.strip)
      end

      re
    end
  end

end ; end ; end
