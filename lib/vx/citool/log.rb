require 'benchmark'

module Vx
  module Citool
    module Log
      def log_command(name)
        print "$ #{name}\n".yellow
      end

      def log_error(name)
        print "#{name}\n".red
      end

      def log_notice(name)
        print "--> #{name}\n".gray
      end

      def log_debug(name)
        print "--> #{name}\n".gray if debug?
      end

      def log_stage(name)
        if true #debug?
          rs = nil
          log "[stage:#{name}:begin]".gray
          tm = Benchmark.measure { rs = yield }
          log "[stage:#{name}:end #{tm.real}]".gray
          rs
        else
          yield
        end
      end

      def debug?
        ENV['DEBUG']
      end

      def log(name)
        puts name
      end

    end
  end
end
