ENV['TZ'] = 'UTC'
require 'test/unit'
require 'rubygems'
require 'active_support'
require 'active_record'
require 'active_record/fixtures'
require 'mocha/setup'
RAILS_ENV = 'test'

require 'active_support/test_case'
require 'active_record/fixtures'
require 'action_pack'
require 'action_controller'
require 'smart_session'


if defined? ActiveRecord::TestFixtures # this is rails 2.3+
  class ActiveSupport::TestCase
    include ActiveRecord::TestFixtures
    self.fixture_path = File.dirname(__FILE__) + "/fixtures/"
    self.use_instantiated_fixtures  = false
    self.use_transactional_fixtures = true

    def with_locking
      SmartSession::SqlSession.lock_optimistically = true
      yield
    ensure
      SmartSession::SqlSession.lock_optimistically = false
    end
  end

  def create_fixtures(*table_names, &block)
    Fixtures.create_fixtures(ActiveSupport::TestCase.fixture_path, table_names, {}, &block)
  end
else
  ActiveSupport::TestCase.fixture_path = File.dirname(__FILE__) + "/fixtures/"
end



RAILS_DEFAULT_LOGGER = ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/debug.log")

database_type = ENV['DATABASE'] || 'mysql2'

config = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))
ActiveRecord::Base.configurations = {'test' => config[database_type]}
ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations['test'])


TEST_SESSION_CLASS =  database_type.to_sym

load(File.dirname(__FILE__) + "/schema.rb")
SmartSession::SqlSession.lock_optimistically = false

