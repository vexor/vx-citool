require "spec_helper"

describe Vx::Citool::Actions::Ruby::RubyVersion do
  describe "#ruby_version" do
    {
      "ruby-2.2.2" => "2.2.2",
      "2.2.2" => "2.2.2",
      "ruby-2.1" => "2.1",
      "ruby-2" => "2",
      "2.1" => "2.1",
      "2.1.10" => "2.1.10"
    }.each do |str, ver|
      describe "version of content #{str}" do
        let(:rubyversion) {described_class.new(content: str)}
        let(:version)     {ver}
        it "should be equal" do
          expect(rubyversion.ruby_version).to eq(version)
        end
      end
    end
  end

  describe "ruby version from location 2.1.1" do
    let(:rubyversion) {described_class.new(path: "spec/fixtures", filename: "ruby-version")}
    let(:version)     {"2.1.1"}
    it "should equal version from file" do
      expect(rubyversion.ruby_version).to eq(version)
    end
  end

  describe "ruby version from locatoin 2.1.10" do
    let(:rubyversion) {described_class.new(path: "spec/fixtures", filename: "ruby-version-2.1.10")}
    let(:version)     {"2.1.10"}
    it "should equal version from file" do
      expect(rubyversion.ruby_version).to eq(version)
    end
  end

  describe "with wrong location" do
    let(:rubyversion) {described_class.new(path: "/tmp")}
    it "should be nil (not raise error)" do
      expect(rubyversion.ruby_version).to be_nil
    end
  end
end

describe Vx::Citool::Actions do
  let(:gemfile) { Vx::Citool::Actions::Ruby::Gemfile.new }
  let(:ruby_version) do
    Vx::Citool::Actions::Ruby::RubyVersion.new(path: "spec/fixtures", filename: "ruby-version-2.1.10")
  end
  let(:vexor_yml_version) { "2.3.3" }

  describe "#ruby_version with Gemfile, .ruby-version and .vexor.yml with ruby version" do
    it "should return version, specified in Gemfile" do
      stub(gemfile).ruby_version { "1.9.3" }
      expect(
        described_class.ruby_version(gemfile, ruby_version, vexor_yml_version)
      ).to eq(gemfile.ruby_version)
    end
  end

  describe "#ruby_version with .ruby-version and .vexor.yml with ruby version" do
    it "should return version, specified in .vexor.yml file" do
      expect(
        described_class.ruby_version(nil, ruby_version, vexor_yml_version)
      ).to eq(vexor_yml_version)
    end
  end

  describe "#ruby_version with .ruby-version" do
    it "should return version, specified in .ruby-version" do
      expect(
        described_class.ruby_version(nil, ruby_version, nil)
      ).to eq(ruby_version.ruby_version)
    end
  end

  describe "#ruby_version when nothing passed" do
    it "should return default ruby version" do
      expect(
        described_class.ruby_version(nil, nil, nil)
      ).to eq(Vx::Citool::Actions::DEFAULT_RUBY_VERSION)
    end
  end
end
