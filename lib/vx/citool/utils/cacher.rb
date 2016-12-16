require 'uri'
require 'shellwords'
require 'fileutils'
module Vx
  module Citool
    module Utils
      class Cacher
        include FileUtils

        attr_reader :cacher_dir, :api_host
        DEFAULT_CACHER_DIR = "/opt/vexor/cache"
        DEFAULT_API_HOST = "https://ci.vexor.io:8080"

        def initialize(params = {})
          @cacher_dir = params[:cacher_dir] || DEFAULT_CACHER_DIR
          @api_host = params[:api_host] || DEFAULT_API_HOST
        end

        # Fetch cache files from storage by url
        def fetch(*urls)
          puts "--> Attempting to download cache archive"
          files = urls.map do |url|
            if cache_was_updated?(url)
              puts "--> Cache was updated... Download new file from storage"
              store_url(url)
            else
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
        end

        def push(url)
          if globaly_changed?
            generate_new_md5!(url)
            archive_all_paths!
            push_chunks(url)
          end
        end

        private

        def cache_was_updated?(url)
          md5_url = append_to_file_url(url, ".md5")
          origin_file_path = File.join(cacher_dir, generate_file_path(md5_url))
          puts "[cache_was_updated?]: #{origin_file_path}"
          if File.exist?(origin_file_path)
            puts "File #{origin_file_path} Founded... Check it"
            check_url = append_to_file_url(md5_url, ".check")
            check_path = generate_file_path(check_url)
            store_url(md5_url, to: check_path)
            return !verify_files_identity(origin_file_path, File.join(cacher_dir, check_path)).tap do |result| 
              FileUtils.rm_rf(File.join(cacher_dir, check_path))
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
          resource_path = File.join(cacher_dir, file_path)
          cmd =  "curl -m 30 -L --tcp-nodelay -f -s %p -o %p >#{cacher_dir}/fetch.log 2>#{cacher_dir}/fetch.err.log" % [url, resource_path]
          puts "[cmd] #{cmd}"
          system cmd
        end

        # Returns boolean value for extracting
        def extract(file_path)
          puts "[extract] #{file_path}"
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

      end
    end
  end
end
