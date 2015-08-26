require "spec_helper"

describe Vx::Citool::Actions do

  subject do
    described_class.invoke_jdk("action" => "install", "version" => "oraclejdk8")
  end

  it "invokes jdk install" do
    re = subject
    expect(re).to be_success

    expect(ENV['JAVA_HOME']).to eq "/usr/lib/jvm/java-8-oracle"

    version = `java -version 2>&1`
    expect(version).to match(/java version "1\.8/)
  end

end
