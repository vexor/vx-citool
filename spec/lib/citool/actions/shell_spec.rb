require 'spec_helper'
require 'timeout'

class ShellTest
  include Vx::Citool::Actions
  include Vx::Citool::Log
end

describe Vx::Citool::Actions, '(shell)' do

  after do
    Vx::Citool.run_teardown
  end

  it "should run command successfuly" do
    re = shell("true")
    expect(re).to be_success
  end

  it "should run command fail" do
    re = shell("false")
    expect(re).to_not be_success
  end

  it "should chdir and run command" do
    re = shell({"command" => "echo $(pwd)", "chdir" => "/"}, {silent: true})
    expect(re).to be_success
    expect(re.data.strip).to eq '/'
  end

  it "should run command detached" do
    re = shell("nohup sleep 1000")
    Timeout.timeout(1) do
      expect(re).to be_success
    end
    expect(File).to be_exists("nohup.log")
  end

  it "should capture environent variable" do
    re = shell("export FOO=BAR")
    expect(re).to be_success
    expect(ENV['FOO']).to eq 'BAR'

    re = shell("export FOO=`pwd`")
    expect(re).to be_success
    expect(ENV['FOO']).to eq Dir.pwd

    re = shell("export FOO=$HOME/$(pwd)")
    expect(re).to be_success
    expect(ENV['FOO']).to eq "#{ENV['HOME']}/#{Dir.pwd}"
  end

  def shell(*args)
    @shell ||= ShellTest.new
    @shell.invoke_shell(*args)
  end

end
