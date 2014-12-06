require File.expand_path("../actions/shell",      __FILE__)
require File.expand_path("../actions/ssh_agent",  __FILE__)
require File.expand_path("../actions/git_clone",  __FILE__)
require File.expand_path("../actions/chdir",      __FILE__)
require File.expand_path("../actions/vxvm",       __FILE__)
require File.expand_path("../actions/ruby",       __FILE__)
require File.expand_path("../actions/cache",      __FILE__)
require File.expand_path("../actions/services",   __FILE__)
require File.expand_path("../actions/python",     __FILE__)
require File.expand_path("../actions/scala",      __FILE__)

module Vx
  module Citool
    module Actions

      Succ = Struct.new(:code, :message, :data) do
        def success? ; true ; end
      end

      Fail = Struct.new(:code, :message, :data) do
        def success? ; false ; end
      end

      NoTests = Struct.new(:orig_message) do
        def success? ; false ; end

        def code  ; 1 ; end
        def message
          "[NO TESTS] #{orig_message}"
        end
      end

      extend self
      extend Log

      def extract_keys(string, *keys)
        Parser.new(string).extract(*keys)
      end

      def normalize_env_value(key_name)
        key_name.to_s.gsub(/\${([^}]+)}/) do |re|
          if $1 == "PWD"
            Dir.pwd
          else
            ENV[$1]
          end
        end
      end


    end
  end
end
