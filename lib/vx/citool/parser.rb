require 'shellwords'

module Vx
  module Citool
    Parser = Struct.new(:string) do
      def extract(*keys)
        rs = { rest: [] }
        values.each do |value|
          found = false
          keys.each do |key|
            re = /\A#{Regexp.escape("#{key}")}=/
            if value.match(re)
              rs[key] = value.sub(re, '')
              found = true
              break
            end
          end

          unless found
            rs[:rest] << value
          end
        end

        rs[:rest] = rs[:rest].join(" ")
        rs
      end

      private

        def values
          @values ||= Shellwords.shellsplit(string)
        end

        def find_key(key_name)
          found = values.find do |value|
            value.match(/#{re}/)
          end
          if found
            re = Regexp.escape("#{key_name}=")
            found.sub(/#{re}/, '')
          end
        end
    end
  end
end
