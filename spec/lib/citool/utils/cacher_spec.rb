require "spec_helper"

describe Vx::Citool::Utils::Cacher do
  subject do
    described_class.new(cache_dir)
  end
  let(:cache_dir) {"/opt/vexor/cache"}

  describe "custom cache directory" do
    let(:cache_dir) {"/home/vexor/.cache"}
    it "setup cached directory" do
      expect(subject.cache_dir).to eq(cache_dir)
    end
  end

  describe "Fetch cached files" do

  end

  describe "Store files to cache" do

  end

end
