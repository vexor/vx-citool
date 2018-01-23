require 'benchmark'

module Vx
  module Citool
    class Stage

      include Citool::Log

      attr_reader :name, :environment, :chdir, :tasks, :vars

      def initialize(options)
        @name        = options["name"]        || "default"
        @environment = options["environment"] || {}
        @chdir       = options["chdir"]
        @tasks       = options["tasks"]       || []
        @vars        = options["vars"]        || {}
      end

      def teardown?
        name == 'teardown'
      end

      def script?
        name == 'script'
      end

      def after_success?
        name == 'after_success'
      end

      def invoke
        log_stage name do
          if chdir
            re = a.invoke_chdir(chdir, persist: true)
            return re unless re.success?
          end

          re, failed = environment.reduce([a::Succ.new(0), []]) do |memo, pair|
            re, prev = memo
            break re, prev unless re.success?
            [add_env(*pair), pair]
          end

          if re.success?
            invoke_tasks
          else
            a::Fail.new(1, "Failed to export #{failed[0]}")
          end
        end
      end

      def invoke_tasks
        re = nil
        tasks.each do |task|
          k,v = Array(task).first
          log_debug "#{k} | #{v.inspect}"
          re = invoke_action(k, v)

          if re.success?
            log_debug "#{k} | success"
          else
            log_debug "#{k} | fail"
          end

          if !after_success? && !re.success?
            break
          end
        end
        re || a::Succ.new(0, "stage #{name} successfuly completed")
      end

      def tasks?
        tasks.any?
      end

      def a
        Actions
      end

      def invoke_action(name, params)
        a.method("invoke_#{name}").call(params, vars: vars)
      end

      private

      def add_env(name, value)
        if value.size > 1096
          Env.export!(name, value)
        end
      end

    end
  end
end
