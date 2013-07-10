require File.join(File.dirname(__FILE__), '../test_helper')

load(File.join(File.dirname(__FILE__), "../schema_custom.rb"))

SmartSession::SqlSession.table_name = "sessions_custom"

class CustomTableNameTest < ActiveSupport::TestCase
  
  SessionKey = '_myapp_session'
  SessionSecret = 'b3c631c314c0bbca50c1b2843150fe33'

  SessionHash = Rack::Session::Abstract::SessionHash
  SmartSessionApp = SmartSession::Store.new(nil, :key => SessionKey, :secret => SessionSecret)
  
  def setup
    @env = { Rack::Session::Abstract::ENV_SESSION_KEY => '123456',  Rack::Session::Abstract::ENV_SESSION_OPTIONS_KEY => Rack::Session::Abstract::ID::DEFAULT_OPTIONS}
  end
  
  def teardown
    SmartSession::SqlSession.delete_all
  end
  
  def test_custom_name
    session = SessionHash.new SmartSessionApp, @env
    session.send :load!
    session[:name] = 'johnny'
    SmartSessionApp.send :set_session, @env, '123456', session.to_hash, {}
    
    assert_equal 'sessions_custom', SmartSession::SqlSession.table_name
    assert_equal 1, SmartSession::SqlSession.count
  end
end
