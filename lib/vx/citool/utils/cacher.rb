require 'shellwords'
require 'fileutils'
require 'yaml'
require 'open-uri'
require 'digest/md5'
require 'base64'
require 'cgi'
require File.expand_path('../redirections_patch', __FILE__)
module Vx
  module Citool
    module Utils
      class Cacher
        include FileUtils
        attr_reader :cache_dir
        attr_reader :mtimes, :mtime_file
        attr_reader :md5_file, :md5sums
        attr_reader :artefacts_tar

        def initialize(cache_dir)
          @cache_dir = cache_dir

          @md5_file = File.expand_path('md5.yml', cache_dir)
          @artefacts_tar = File.expand_path('artefacts.tar', cache_dir)

          @mtime_file = File.expand_path('mtime.yml', cache_dir)
          @mtimes = File.exist?(mtime_file) ? YAML.load_file(mtime_file) : {}

          mkdir_p cache_dir
        end

        def fetch(*urls)
          puts "--> Attempting to download cache archive"
          res = urls.any? do |url|
            artefact_url, md5sums_url = parse_body(fetch_body(url))
            if md5_summ_changed?(md5sums_url)
              cmd =  "curl -m 30 -L --tcp-nodelay -f -s %p -o %p >#{cache_dir}/fetch.log 2>#{cache_dir}/fetch.err.log" % [artefact_url, artefacts_tar]
              system cmd
            end
          end

          if res
            puts "found cache"
            puts "extracting checksums"
            tar(:x, artefacts_tar, md5_file) { puts "checksums not yet calculated, skipping" }
          else
            puts "could not download cache"
            if File.exist? artefacts_tar
              rm artefacts_tar
            end
          end
        end

        def add(*paths)
          paths.each do |path|
            add_path(path)
          end
          File.open(mtime_file, 'w') { |f| f << mtimes.to_yaml }
        end

        def push(url)
          if changed?
            puts "changes detected, packing new archive"
            store_md5
            tar(:c, push_tar, md5_file, *mtimes.keys)
            #TODO: Add md5sum url and uploading md5sum
            new_url = fetch_body(url)
            if new_url
              push_chunks(new_url)
            else
              puts "failed to retrieve cache url"
            end
          else
            puts "nothing changed, not updating cache"
          end
        end

        private

        def add_path(path)
          path = File.expand_path(path)
          puts "adding #{path} to cache"
          mkdir_p path
          tar(:x, artefacts_tar, path) { puts "#{path} is not yet cached" }
          mtimes[path] = Time.now.to_i
        end

        def push_chunks(url)
          re = [ push_tar ].all? do |file|
            cmd = "curl -XPUT -s -S -m 60 -T %p %p" % [file, url]
            print "."
            system cmd
          end

          print(re ? " OK\n" : " FAIL\n")
          return false unless re
        end

        def changed?
          return true unless File.exist? artefacts_tar
          each_file do |file, mtime|
            next if unchanged? file, mtime
            puts "#{file} was modified"
            return true
          end
          return false
        end

        def unchanged?(file, mtime)
          return false unless md5sums[file]
          return true  if unchanged_mtime?(file, mtime)
          md5sums[file] == md5(file)
        end

        def unchanged_mtime?(file, mtime)
          File.mtime(file).to_i <= mtime
        end

        def md5sums
          @md5sums ||= File.exist?(md5_file) ? YAML.load_file(md5_file) : {}
        end

        def md5(file)
          sum = `md5sum #{Shellwords.escape(file)}`.split(" ", 2).first
          sum.to_s.empty? ? Time.now.to_i : sum
        end

        def store_md5
          new_md5sums = {}
          each_file do |file, mtime|
            if unchanged_mtime?(file, mtime) && md5sums.include?(file)
              new_md5sums[file] = md5sums[file]
            else
              new_md5sums[file] = md5(file)
            end
          end
          File.open(md5_file, 'w') { |f| f << new_md5sums.to_yaml }
        end

        def each_file
          mtimes.each do |path, mtime|
            Dir.glob("#{path}/**/*") do |file|
              yield file, mtime unless File.directory?(file)
            end
          end
        end

        def tar(flag, file, *args, &block)
          command = "tar -Pz#{flag}f #{Shellwords.escape(file)} #{Shellwords.join(args)}"
          block ||= proc { puts "FAILED: #{command}", File.read("#{cache_dir}/tar.err.log"), File.read("#{cache_dir}/tar.log") }
          block.call unless system "#{command} 2>#{cache_dir}/tar.err.log >#{cache_dir}/tar.log"
        end

        # Should return artefact_url and MD5_sums url
        # Look at vx-web API
        def fetch_body(url)
          begin
            puts "Fetch cache url: #{url}"
            open(url, allow_redirections: :safe) {|io| io.gets }
          rescue Exception => e
            $stderr.puts "#{e.class} - #{e.message}"
          end
        end

        # Parse response and
        # returns array of [artefact_url, md5sums_url]
        def parse_body(body)
          puts "--> BODY: #{body}"
          return []
        end

        def md5_summ_changed?(md5_url)
          false
        end

      end
    end
  end
end
