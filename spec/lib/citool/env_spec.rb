require 'spec_helper'

describe Vx::Citool::Env do
  subject { described_class }
  let!(:file) { StringIO.new }

  before do
    described_class.set_default_file file
  end

  after do
    file.close unless file.closed?
    described_class.set_default_file :tempfile
  end

  it "#export!" do
    subject.export!("TEST", "test_val")
    expect(ENV['TEST']).to eq "test_val"
    expect(file.string).to eq "export TEST=\"test_val\"\n"
  end

  it "#persist_var!" do
    subject.persist_var!("TEST", "test_val")
    expect(file.string).to eq "export TEST=\"test_val\"\n"
  end

  it "#persist_arbitrary!" do
    subject.persist_arbitrary!("exec echo hey there")
    expect(file.string).to eq "exec echo hey there\n"
  end


  it "#normalize" do
    ENV['TEST_ME'] = "1"
    expect(subject.normalize("${PWD}")).to eq Dir.pwd
    expect(subject.normalize("${TEST_ME}")).to eq "1"
  end

end
