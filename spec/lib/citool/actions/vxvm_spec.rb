require 'spec_helper'
require 'ostruct'

describe Vx::Citool::Actions do
  subject { described_class.invoke_vxvm("ruby") }

  class FakeIO
    attr_reader :string

    def initialize
      @string = ""
    end

    def close; end

    def puts(data)
      @string << "#{data}\n"
    end
  end

  let!(:file) { FakeIO.new }

  before do
    Vx::Citool::Env.set_default_file file
    stub(described_class).invoke_shell do
      OpenStruct.new(
        success?: true,
        data: <<env_file
TESTVXVM1=test_1
TESTVXVM2=test_2
env_file
      )
    end
  end

  after do
    Vx::Citool::Env.set_default_file :tempfile
  end

  it "exports and persists activate scripts" do
    subject

    expect(ENV['TESTVXVM1']).to eq "\"test_1\""
    expect(ENV['TESTVXVM2']).to eq "\"test_2\""
    expect(file.string).to eq "export TESTVXVM1=\"test_1\"\nexport TESTVXVM2=\"test_2\"\n"
  end
end
