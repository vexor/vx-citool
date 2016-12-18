require 'open-uri'
require 'json'
require 'yaml'
require 'shellwords'
require 'fileutils'
require File.expand_path('../redirections_patch', __FILE__)
module Vx
  module Citool
    module Utils
      class Cacher
        include FileUtils

        attr_reader :cacher_dir, :api_host
        attr_reader :global_storage_path
        attr_reader :tmime_file, :mtimes_storage
        attr_reader :md5_file, :md5_storage
        DEFAULT_CACHER_DIR = "/opt/vexor/cache"
        DEFAULT_API_HOST = "https://ci.vexor.io:8080"

        def initialize(params = {})
          @cacher_dir = params[:cacher_dir] || DEFAULT_CACHER_DIR
          @api_host = params[:api_host] || DEFAULT_API_HOST

          @global_storage_path = File.expand_path("~/.cacher/")
          system "sudo mkdir -p #{global_storage_path} && sudo chown vexor -R #{global_storage_path}"
          system "sudo mkdir -p #{cacher_dir} && sudo chown vexor -R #{cacher_dir}"
          @tmime_file = File.join(global_storage_path, "tmime.yml")
          @mtimes_storage = File.exist?(tmime_file) ? YAML.load_file(tmime_file) : {}
        end

        # Fetch cache files from storage by url
        def fetch(*urls)
          puts "--> Attempting to download cache archive"
          files = urls.map do |url|
            url, md5_url = *decode_urls(url)
            if cache_was_updated?(url, md5_url) && !locked?(url)
              puts "--> Cache was updated... Download new file from storage"
              with_lock(url) do
                store_url(url)
              end
            else
              wait_while_locked!(url)
              puts "--> No reason to fetch new cache. Get local copy."
              generate_file_path(url)
            end
          end

          files.all? do |filename|
            extract(filename)
          end
        end

        def add(*paths)
          paths.each do |path|
            add_path(path)
          end
          File.open(tmime_file, 'w') { |f| f << mtimes_storage.to_yaml }
        end

        def push(url)
          url, md5_url = *decode_urls(url)
          if locked?(url)
            puts "--> Pushing now in other job... skip pushing "
            return
          end
          target_file = absolute_path(generate_file_path(url)) 
          @md5_file = absolute_path(generate_file_path(md5_url))
          @md5_storage = File.exist?(md5_file) ? YAML.load(md5_file) : {}
          if globaly_changed?
            with_lock(url) do
              generate_new_md5!(md5_file)
              archive_all_paths!(target_file)
              push_chunks(target_file, url)
              push_chunks(md5_file, md5_url)
            end
          end
        end

        private

        def with_lock(url)
          begin
            lock!(url)
            yield
          ensure
            unlock!(url)
          end
        end

        def lock!(url)
          lock_file = "#{absolute_path(generate_file_path(url))}.lock"
          system "sudo mkdir -p #{File.dirname(lock_file)} && sudo chown vexor -R #{File.dirname(lock_file)}"
          puts ">>> Lock download file: #{lock_file}"
          touch(lock_file)
        end

        def unlock!(url)
          lock_file = "#{absolute_path(generate_file_path(url))}.lock"
          puts ">>> Unlock download file: #{lock_file}"
          rm_rf(lock_file)
        end

        def locked?(url)
          lock_file = "#{absolute_path(generate_file_path(url))}.lock"
          puts "check lock_file: #{lock_file}"
          File.exist?(lock_file)
        end

        def wait_while_locked!(url)
          while locked?(url)
            sleep 1
          end
        end

        def absolute_path(relitive_path)
          File.join(cacher_dir, relitive_path)
        end

        def add_path(path)
          path = File.expand_path(path)
          puts "adding #{path} to cache"
          system "sudo mkdir -p #{path} && sudo chown vexor -R #{path}"
          mtimes_storage[path] = Time.now.to_i
        end

        def unchanged_mtime?(file, mtime)
          File.mtime(file).to_i <= mtime
        end

        def decode_urls(url)
          data = open(url, allow_redirections: :safe) {|io| io.gets }
          return JSON.parse(data)
        end

        def cache_was_updated?(url, md5_url)
          origin_file_path = absolute_path(generate_file_path(md5_url))
          if File.exist?(origin_file_path)
            puts "File #{origin_file_path} Founded... Check it"
            check_url = append_to_file_url(md5_url, ".check")
            check_path = generate_file_path(check_url)
            store_url(md5_url, to: check_path)
            return !verify_files_identity(origin_file_path, absolute_path(check_path)).tap do |result| 
              rm_rf(absolute_path(check_path))
            end
          else
            puts "File #{origin_file_path} not found... Download new file"
            store_url(md5_url)
            return true
          end
        end

        # Returns relitive file path
        def generate_file_path(url)
          URI.parse(url).path
        end

        # Returns file path
        def store_url(url, opts = {})
          file_path = opts[:to] || generate_file_path(url)
          resource_path = absolute_path(file_path)
          dirname = File.dirname(resource_path)
          system "sudo mkdir -p #{dirname} && sudo chown vexor -R #{dirname}"
          cmd =  "curl -m 30 -L --tcp-nodelay -f -s %p -o %p >#{cacher_dir}/fetch.log 2>#{cacher_dir}/fetch.err.log" % [url, resource_path]
          system cmd
          return file_path
        end

        # Returns boolean value for extracting
        def extract(file_path)
          puts "Try to extract #{file_path}"
          if file_path 
            file_path = absolute_path(file_path)
            puts "[extract] #{file_path}"
            tar(:x, file_path) { puts "checksums not yet calculated, skipping" }
          else
            return false
          end
        end

        def append_to_file_url(url, suffix="")
          URI.parse(url).tap do |new_url| 
            new_url.path += suffix
          end.to_s
        end

        def verify_files_identity(origin_file, checked_file)
          puts "[verify_files_identity]: \norigin_file:  #{origin_file}\nchecked_file: #{checked_file}"
          md5(origin_file) == md5(checked_file)
        end

        def md5(file)
          begin
            sum = `md5sum #{Shellwords.escape(file)}`.split(" ", 2).first
            sum.to_s.empty? ? Time.now.to_i : sum
          rescue
            Time.now.to_i
          end
        end

        def tmime_path
          File.join(global_storage_path, "tmime.yml")
        end

        # Check all files for changes its mtime
        def globaly_changed?
          return generate_md5_sums != md5_storage
        end

        def each_file
          mtimes_storage.each do |path, mtime|
            Dir.glob("#{path}/**/*") do |file|
              yield file, mtime unless File.directory?(file)
            end
          end
        end

        def generate_md5_sums
          puts "Generate new md5_sum file"
          new_md5sums = {}
          each_file do |file, mtime|
            if unchanged_mtime?(file, mtime) && md5_storage[file]
              new_md5sums[file] = md5_storage[file]
            else
              new_md5sums[file] = md5(file)
            end
          end
          return new_md5sums
        end

        def generate_new_md5!(md5_file)
          directory = File.dirname(md5_file)
          system "sudo mkdir -p #{directory} && sudo chown vexor -R #{directory}"
          File.open(md5_file, 'w') { |f| f << generate_md5_sums.to_yaml }
        end

        def archive_all_paths!(target_file)
          puts "Archive to file #{target_file}"
          tar(:c, target_file, *mtimes_storage.keys)
        end

        def tar(flag, file, *args, &block)
          tar_bin = ENV["TAR_BIN"] || "tar"
          command = "#{tar_bin} -Pz#{flag}f #{Shellwords.escape(file)} #{Shellwords.join(args)}"
          block ||= proc { puts "FAILED: #{command}", File.read("#{cacher_dir}/tar.err.log"), File.read("#{cacher_dir}/tar.log") }
          block.call unless system "#{command} 2>#{cacher_dir}/tar.err.log >#{cacher_dir}/tar.log"
        end

        def push_chunks(push_tar, url)
          re = [ push_tar ].all? do |file|
            cmd = "curl -XPUT -s -S -m 60 -T %p %p" % [file, url]
            print "."
            system cmd
          end

          print(re ? " OK\n" : " FAIL\n")
          return false unless re
        end
      end
    end
  end
end
