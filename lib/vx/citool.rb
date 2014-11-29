require 'yaml'
require File.expand_path("../citool/log",        __FILE__)
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

    def load(file)
      content = File.read(file)
      yaml = YAML.load(content)

      re = nil
      begin

        yaml.each do |stage_options|
          stage = Stage.new(stage_options)
          re    = stage.invoke
          break unless re.success?
        end
      ensure
        @@teardown.map(&:call)
      end

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
