require 'spec_helper'

describe Vx::Citool::Stage do
  let(:environment) do
    {
      "TEST_EXPAND" => "~",
      "TEST_SECRET" => "!secret",
      "TEST_ENV"    => "test_env"
    }
  end

  subject {
    described_class.new("environment" => environment).invoke
  }

  context "environment" do
    before { subject }

    it "expands env" do
      expect(ENV['TEST_EXPAND']).to match(/#{ENV['USER']}\z/)
    end

    it "adds secret env" do
      expect(ENV['TEST_SECRET']).to eq "secret"
    end

    it "adds env" do
      expect(ENV['TEST_ENV']).to eq "test_env"
    end
  end
end