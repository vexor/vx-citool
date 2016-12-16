require File.expand_path '../../lib/vx/citool', __FILE__
Bundler.require(:test)
require 'webmock/rspec'

spec = File.dirname(__FILE__)

Vx::Citool::Env.set_default_file :tempfile

RSpec.configure do |config|
  config.mock_with :rr
end
