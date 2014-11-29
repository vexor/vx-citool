require 'fileutils'

task :default do
  FileUtils.rm_rf "tmp/.ssh"
  FileUtils.rm_rf "tmp/.casher"
  FileUtils.rm_rf "tmp/vexor"
  exec %{ sh -c "cat spec/fixtures/simple.yml | HOME=$(pwd)/tmp bin/vx-citool -" }
end
