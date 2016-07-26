module Vx
  module Citool

    module Actions

      CASHER = File.expand_path("../../scripts/casher", __FILE__)

      def invoke_cache_fetch(args, options = {})
        url    = args["url"].join(" ")
        invoke_shell("#{CASHER} fetch #{url}", hidden: true)
      end

      def invoke_cache_add(args, options = {})
        files = args["dir"].join(" ")
        invoke_shell("#{CASHER} add #{files}", hidden: true)
      end

      def invoke_cache_push(args, options = {})
        url = args["url"]
        invoke_shell("#{CASHER} push #{url}", hidden: true)
      end
    end

  end
end
