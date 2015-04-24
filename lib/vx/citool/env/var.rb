module Vx
  module Citool
    module Env
      class Var
        def initialize(key, value, opts = {})
          @key, @opts = key, opts
          @value      = Env.normalize(value)
        end

        def secure?
          @secure ||= @value[0] == "!"
        end

        def log_value
          "export " +
          "#{@key}=#{secure? ? secure_value : @value}"
        end

        def export_value
          "export " +
          "#{@key}=#{secure? ? @value[1..-1] : @value}"
        end

        def secure_value
          @value.gsub(/[^\s]/, '*')
        end
      end
    end
  end
end
