require File.join(File.dirname(__FILE__), '../test_helper')

if defined? ActionController::Session::AbstractStore

class SmartSessionTest < ActiveSupport::TestCase
  fixtures :sessions
  
  SessionKey = '_myapp_session'
  SessionSecret = 'b3c631c314c0bbca50c1b2843150fe33'

  SessionHash = ActionController::Session::AbstractStore::SessionHash
  # DispatcherApp = ActionController::Dispatcher.new
  SmartSessionStoreApp = SmartSessionStore.new(nil, :key => SessionKey, :secret => SessionSecret)
  
  #short circuit this so that the session id us our static one
  def SmartSessionStoreApp.load_session(env)
    sid, session = get_session(env, '123456')
    [sid, session]
  end
  # Replace this with your real tests.
  def setup
    @env = { ActionController::Session::AbstractStore::ENV_SESSION_KEY => '123456',  ActionController::Session::AbstractStore::ENV_SESSION_OPTIONS_KEY => ActionController::Session::AbstractStore::DEFAULT_OPTIONS}
  end
  
  def test_simultaneous_access_session_already_created
    setup_base_session do |base_session|
      base_session[:last_viewed_page] = 'home'
    end
        
    do_simultaneous_session_access do |first_data, second_data|
      first_data[:user_id] = 123
      first_data[:last_viewed_page] = 'news'
      second_data[:favourite_food] = 'pizza'
    end
    
    assert_final_session :user_id => 123, :favourite_food => 'pizza', :last_viewed_page => 'news'
  end
  
  def test_simultaneous_access_session_not_created
    do_simultaneous_session_access do |first_data, second_data|
      first_data[:user_id] = 123
      second_data[:favourite_food] = 'pizza'
    end
    
    assert_final_session :user_id => 123, :favourite_food => 'pizza'
  end
  
  def test_simultaneous_access_delete_keys
    
    setup_base_session do |base_session|
      base_session[:key_to_delete] = 123
      base_session[:key_to_preserve] = 456
    end
    
    do_simultaneous_session_access do |first_data, second_data|
      first_data[:user_id] = 789      
      first_data.delete :key_to_delete
      first_data[:key_to_preserve] = 123
      second_data[:favourite_food] = 'pizza'
    end
    
    assert_final_session :key_to_preserve => 123, :favourite_food => 'pizza', :user_id => 789
  end
  
  def test_deep_session_object
    setup_base_session do |base_session|
      base_session[:flash] = {:notice => 'Please login'}
    end
    
    setup_base_session do |base_session|
      base_session[:flash][:notice] = 'Thanks for logging in'
    end
    assert_final_session( :flash => {:notice => 'Thanks for logging in'})
  end
  
  class ClassWithOddEqual < Hash
    attr_accessor :ivar
  end
  
  def test_objects_with_odd_equal
    w = ClassWithOddEqual.new
    w[:name] = 'paul'
    
    setup_base_session do |base_session|
      base_session[:flash] = w
    end
    
    w.ivar = 123
    
    setup_base_session do |base_session|
      base_session[:flash] = w
    end
    
    setup_base_session do |base_session|
      assert_equal base_session[:flash].ivar, 123
    end
    
  end
  
  private
  
  def assert_final_session expected
    consolidated_session = SessionHash.new(SmartSessionStoreApp, @env.dup)
    consolidated_session.send :load!
    assert_equal expected, consolidated_session.to_hash
  end
  
  def setup_base_session
    duped_env = @env.dup
    base_session = SessionHash.new(SmartSessionStoreApp, duped_env)
    base_session.send :load!
    yield base_session if block_given?
    SmartSessionStoreApp.send :set_session, duped_env, '123456', base_session.to_hash
  end
  
  def do_simultaneous_session_access
    first_env = @env.dup
    second_env = @env.dup
    first_session = SessionHash.new(SmartSessionStoreApp, first_env)
    second_session = SessionHash.new(SmartSessionStoreApp, second_env)
        
    yield first_session, second_session
    SmartSessionStoreApp.send :set_session, first_env, '123456', first_session.to_hash
    SmartSessionStoreApp.send :set_session, second_env, '123456', second_session.to_hash
    
  end
end

end