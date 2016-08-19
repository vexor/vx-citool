module Vx
  module Citool

    module Actions
      DEFAULT_BUNDLER_ARGS = "--clean --retry=3 --jobs=4"

      PG_CONFIG = "
test:
  adapter: postgresql
  encoding: unicode
  database: rails_test
  username: postgres
  host: localhost
"
      MYSQL2_CONFIG = "
test:
   adapter:   mysql2
   encoding:  utf8
   database:  rails_test
   username:  root
   host:      localhost
   collation: utf8_general_ci
"
      SQLITE3_CONFIG = "
test:
  adapter: sqlite3
  database: db/test.sqlite3
"
      MONGOID_CONFIG = "
test:
  sessions:
    default:
      database: mongoid
      hosts:
        - localhost:27017
"
      module Ruby

        Secrets = Struct.new(:owner, :gemfile) do

          FILE = "config/secrets.yml"

          def present?
            if File.exists?(FILE)
              begin
                content = File.read(FILE)
                content.match(/^test\:/)
              rescue Exception
              end
            end
          end

          def create
            if !present? && gemfile.rails? && File.directory?("config")
              owner.log_notice "apply patch to config/secrets.yml"
              File.open(FILE, 'a') {|io| io.write "\n\ntest:\n  secret_key_base: secret\n" }
            else
              owner.log_notice "keep config/secrets.yml"
            end
          end
        end

        class RubyVersion
          VERSION_REGEXP = /(((\d\.){1,2})?\d)/mx
          attr_reader :path, :filename

          def initialize(args = {})
            @path     = args.fetch(:path, Dir.pwd)
            @filename = args.fetch(:filename, ".ruby-version")
            @content  = args[:content]
          end

          def ruby_version
            if content && content.match(VERSION_REGEXP)
              $1
            end
          end

          def content
            @content ||= (File.read(location) if exists?)
          end

          def location
            @location ||= File.join(path, filename)
          end

          def exists?
            File.exists?(location) && File.file?(location)
          end
        end

        class Gemfile
          def location
            @location ||= ENV['BUNDLE_GEMFILE'] || "#{Dir.pwd}/Gemfile"
          end

          def content
            if exists?
              @content ||= File.read(location)
            end
          end

          def ruby_version
            if content && content.match(/ruby +['"](.*)['"]/)
              $1
            end
          end

          def gem?(name)
            name = Regexp.escape(name)
            content && content.match(/gem +['"]#{name}['"]/)
          end

          def exists?
            File.exists?(location)
          end

          def rails?
            gem?('rails')
          end

        end

        Database = Struct.new(:owner, :gemfile) do

          def create
            re = nil

            if gemfile.gem?(:rails) and File.exists?("config/application.rb") and !database_ci
              re =
                (
                  create_pg_config     ||
                  create_mysql2_config ||
                  create_sqlite3_config
                ) && (
                  setup
                )
              return re if re && !re.success?
            end

            if gemfile.gem?("mongoid")
              re = create_mongoid_config
              return re unless re.success?
            end

            re || owner::Succ.new(0, "database tasks was successfuly processed")
          end

          def setup
            re = owner.invoke_shell "bundle exec rake db:create"
            return re unless re.success?

            if File.exists?("db/schema.rb")
              re = owner.invoke_shell("bundle exec rake db:schema:load", silent: true)
              return re unless re.success?
            end

            if File.directory?("db/migrate")
              re = owner.invoke_shell("bundle exec rake db:migrate", silent: true)
              return re unless re.success?
            end

            re
          end

          # TODO: remove
          def database_ci
            File.exists?("config/database.yml.ci")
          end

          def create_mongoid_config
            File.open("config/mongoid.yml", 'w') {|io| io.write MONGOID_CONFIG.strip }
            owner.log_notice "create config/mongoid.yml"
            FileUtils.ln_s File.expand_path("config/mongoid.yml"), File.expand_path("mongoid.yml")
            owner.invoke_shell("sudo service mongodb start")
          end

          def create_pg_config
            if gemfile.gem?("pg")
              owner.log_notice "create config/database.yml for postgres"
              File.open('config/database.yml', 'w') { |io| io.write PG_CONFIG.strip }
            end
          end

          def create_mysql2_config
            if gemfile.gem?("mysql2")
              owner.log_notice "create config/database.yml for mysql"
              File.open('config/database.yml', 'w') { |io| io.write MYSQL2_CONFIG.strip }
            end
          end

          def create_sqlite3_config
            if gemfile.gem?("sqlite3")
              owner.log_notice "create config/database.yml for sqlite"
              File.open('config/database.yml', 'w') { |io| io.write SQLITE3_CONFIG.strip }
            end
          end

        end
      end

      def invoke_ruby(args, options = {})
        rubyversion = Ruby::RubyVersion.new
        gemfile     = Ruby::Gemfile.new
        database    = Ruby::Database.new self, gemfile
        secrets     = Ruby::Secrets.new self, gemfile

        if args.is_a?(String)
          action = args
          args   = {}
        else
          action = args["action"]
        end

        case action

        when "install"
          version =
            if r = rubyversion.ruby_version || gemfile.ruby_version
              if args['ruby']
                if args['ruby'].to_s.match(/^#{Regexp.escape r}/)
                  args['ruby']
                else
                  log_notice "Force using the ruby version '#{r}' instead '#{args['ruby']}', specified in the Gemfile"
                  r
                end
              else
                r
              end
            else
              args["ruby"]
            end
          re = invoke_vxvm("ruby #{version}")
          return re unless re.success?

          if ENV['GEM_HOME']
            re = invoke_shell("export PATH=$GEM_HOME/bin:$PATH")
          end
          return re unless re.success?

          unless ENV["NOKOGIRI_USE_SYSTEM_LIBRARIES"]
            re = invoke_shell("export NOKOGIRI_USE_SYSTEM_LIBRARIES=1")
          end

          re

        when 'announce'
          re = invoke_shell("ruby --version")
          return re unless re.success?

          re = invoke_shell("gem --version")
          return re unless re.success?

          re = invoke_shell("bundle --version")
          return re unless re.success?

          re

        when "bundle:install"
          re = invoke_shell "bundle install #{args["bundler_args"] || DEFAULT_BUNDLER_ARGS}"
          return re unless re.success?

          secrets.create
          re

        when "rails:database"
          database.create

        when "script"
          invoke_shell "bundle exec rake"
        end
      end
    end

  end
end
