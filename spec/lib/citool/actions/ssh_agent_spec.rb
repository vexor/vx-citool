require 'spec_helper'
require 'yaml'

describe Vx::Citool::Actions do
  let(:ssh_dir) { File.expand_path 'spec/tmp' }
  let(:pid) do
    subject.data[:pid]
  end

  after do
    puts "Shutting down ssh-agent with pid #{pid}..."
    Process.kill(:KILL, pid)
    Process.wait(pid)
  end

  subject do
    described_class.extend described_class
    described_class.invoke_ssh_agent(args, ssh_dir: ssh_dir)
  end

  %w(string array).each do |kind|
    context "#{kind}" do
      let!(:args) do
        path = File.expand_path "spec/fixtures/keys_#{kind}.yml"
        YAML.load_file(path)[0]["tasks"][0]["ssh_agent"]
      end

      it "creates and adds ssh keys" do
        subject

        n = kind == "array" ? 3 : 1
        n.times do |i|
          name = "id#{i}_rsa"
          expect(File).to exist(File.expand_path ssh_dir, name)
          expect(File).to exist(File.expand_path ssh_dir, "#{name}.pub")
          expect(`ssh-add -l`).to match %r[#{name}]
        end
      end
    end
  end
end