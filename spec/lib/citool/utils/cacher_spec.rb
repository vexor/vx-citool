require "spec_helper"

describe Vx::Citool::Utils::Cacher do
  subject do
    described_class.new(cacher_dir: cacher_dir,
                        api_host: api_host)
  end
  let(:cacher_dir) {"/opt/vexor/cache"}
  let(:api_host)   {"http://localhost:3000"}

  describe "custom cache directory" do
    let(:cacher_dir) {"/home/vexor/.cache"}
    it "setup cached directory" do
      expect(subject.cacher_dir).to eq(cacher_dir)
    end
  end

  describe "Fetch cached files" do
    let(:urls) {["http://storage.local/project_id/branch/cache.tgz"]}

    context "No local cache files, no storage" do
      it "should do nothing" do
        expect(subject.fetch(*urls)).not_to be_truthy
      end
    end

    context "No local cache files, but there are on storage" do
      it "should download and extract new cache files" do
        expect(subject.fetch(*urls)).to be_truthy
      end
    end

    context "Have local cache files" do
    end
  end
end
