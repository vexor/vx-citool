require 'fileutils'

task :default do
  FileUtils.rm_rf "tmp"
  exec %{ sh -c "HOME=$(pwd)/tmp bin/vx-citool spec/fixtures/simple.yml" }
end
