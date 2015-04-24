require "spec_helper"

describe Vx::Citool::Actions do

  subject do
    -> (options){
      described_class.invoke_chdir("~/", options)
    }
  end

  before(:all) { @dir = Dir.pwd }
  after(:all) { Dir.chdir @dir }


  before do
    Vx::Citool::Env.set_default_file file
  end

  after do
    Vx::Citool::Env.set_default_file :tempfile
  end

  let(:args) { "~" }
  let(:file) { StringIO.new }

  it "invokes cd" do
    subject[{}]
    expect(Dir.pwd).to eq Dir.home
  end

  it "invokes cd and persists it" do
    subject[{persist: true}]
    expect(Dir.pwd).to eq Dir.home
    expect(file.string).to eq "cd #{Dir.home}\n"
  end
end
