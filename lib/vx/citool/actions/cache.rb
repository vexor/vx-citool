module Vx
  module Citool

    module Actions

      CASHER = File.expand_path("../../scripts/casher", __FILE__)

      def invoke_cache_fetch(args, options = {})
        args = extract_keys(args)

        url    = args[:rest]
        invoke_shell("#{CASHER} fetch #{url}", hidden: true)
      end

      def invoke_cache_add(args, options = {})
        args = extract_keys(args)

        files = args[:rest]
        invoke_shell("#{CASHER} add #{files}", hidden: true)
      end

      def invoke_cache_push(args, options = {})
        args = extract_keys(args)

        url = args[:rest]
        invoke_shell("#{CASHER} push #{url}", hidden: true)
      end
    end

  end
end
