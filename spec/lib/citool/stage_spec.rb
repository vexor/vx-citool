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

    it "expands env" do
      expect(subject.code).to eq 0
      expect(ENV['TEST_EXPAND']).to match(/#{ENV['USER']}\z/)
    end

    it "adds secret env" do
      expect(subject.code).to eq 0
      expect(ENV['TEST_SECRET']).to eq "secret"
    end

    it "adds env" do
      expect(subject.code).to eq 0
      expect(ENV['TEST_ENV']).to eq "test_env"
    end
  end

  context "failing environment" do
    let(:environment) do
      { "GOOD_VAR" => "good_var",
        "BAD_VAR" => "bad var (is here)",
        "GOOD_VAR2" => "good_var_2"
      }
    end

    it "fails" do
      expect(subject.code).not_to eq 0
    end
  end
end