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

    re = shell("export FOO=~/.dir")
    expect(re).to be_success
    expect(ENV['FOO']).to eq "#{ENV['HOME']}/.dir"

    re = shell("export FOO=\"~/.dir\"")
    expect(re).to be_success
    expect(ENV['FOO']).to eq "~/.dir"
  end

  it "should run with pipes" do
    re = shell("seq 1 100 | grep --color=none 33", silent: true)
    expect(re).to be_success
    expect(re.data).to eq "33\r\n"
  end

  it "should run with quotes" do
    re = shell("echo \"foo bar\"", silent: true)
    expect(re).to be_success
    expect(re.data).to eq "foo bar\r\n"

    re = shell("echo 'foo bar'", silent: true)
    expect(re).to be_success
    expect(re.data).to eq "foo bar\r\n"

    re = shell("echo foo\ bar", silent: true)
    expect(re).to be_success
    expect(re.data).to eq "foo bar\r\n"
  end

  it "should replace source to ." do
    re = shell("source ./test_env")
    expect(re.message).to match %r{^The command '\. \.\/test_env ; env' .+}
  end

  it "source loads env" do
    re = shell("source #{File.expand_path "./spec/fixtures/test_env"}")
    expect(re).to be_success
    expect(ENV['SOURCE']).to eq "working"
  end



  def shell(*args)
    @shell ||= ShellTest.new
    @shell.invoke_shell(*args)
  end

end
