require File.expand_path '../../lib/vx/citool', __FILE__
Bundler.require(:test)

spec = File.dirname(__FILE__)

RSpec.configure do |config|
  config.mock_with :rr
end

