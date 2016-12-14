require 'yaml'

require File.expand_path("../citool/log",          __FILE__)
require File.expand_path("../citool/actions",      __FILE__)
require File.expand_path("../citool/stage",        __FILE__)
require File.expand_path("../citool/string",       __FILE__)
require File.expand_path("../citool/env/var",      __FILE__)
require File.expand_path("../citool/env",          __FILE__)
require File.expand_path("../citool/utils/cacher", __FILE__)

module Vx
  module Citool

    extend Log

    @@teardown = []

    extend self

    def teardown(&block)
      @@teardown << block
    end

    def run_stage(stage_options)
      stage = Stage.new(stage_options)
      stage.invoke
    end

    def run_teardown
      @@teardown.map(&:call)
    end

    def process(content)
      yaml = YAML.load(content)
      state_file = File.expand_path("~/.ci_state")

      File.open(state_file, 'w') {|io| io.write "before_script" }

      re = nil
      begin

        teardown_stage = nil

        stages = yaml.inject([]) do |a, stage_options|
          stage = Stage.new(stage_options)
          if stage.teardown?
            teardown_stage = stage
          else
            a.push stage
          end
          a
        end

        stages.each do |stage|

          if stage.script?
            File.open(state_file, 'w') {|io| io.write "script" }
          end

          if stage.after_success?
            stage.invoke
          else
            re = stage.invoke
          end

          break unless re.success?
        end

        finish(re)

        if teardown_stage
          teardown_stage.invoke
        end
      ensure
        run_teardown
      end

      re
    end

    def finish(re)
      if re
        m =
          if re.success?
            re.message.green
          else
            re.message.red
          end
        log ""
        log m
        log ""
      end
    end

  end
end
