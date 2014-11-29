require 'yaml'

require File.expand_path("../citool/log",        __FILE__)
require File.expand_path("../citool/parser",     __FILE__)
require File.expand_path("../citool/actions",    __FILE__)
require File.expand_path("../citool/stage",      __FILE__)
require File.expand_path("../citool/string",     __FILE__)

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

    def process(content)
      yaml = YAML.load(content)

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
          re    = stage.invoke
          break unless re.success?
        end

        finish(re)

        if teardown_stage
          teardown_stage.invoke
        end
      ensure
        @@teardown.map(&:call)
      end

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
