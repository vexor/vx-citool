require "spec_helper"

describe Vx::Citool::Actions::Ruby::RubyVersion do
  describe "#ruby_version" do
    {
      "ruby-2.2.2" => "2.2.2",
      "2.2.2" => "2.2.2",
      "ruby-2.1" => "2.1",
      "ruby-2" => "2",
      "2.1" => "2.1"
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

  describe "ruby version from locatoin" do
    let(:rubyversion) {described_class.new(path: "spec/fixtures", filename: "ruby-version")}
    let(:version)     {"2.1.1"}
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
