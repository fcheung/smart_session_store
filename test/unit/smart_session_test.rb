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
    SmartSessionStore.session_class = TEST_SESSION_CLASS
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


ActionController::Base.session_store = nil
class FullStackTest < ActionController::IntegrationTest
  fixtures :sessions
  
  DispatcherApp = ActionController::Dispatcher.new
  SessionApp = SmartSessionStore.new(DispatcherApp,   :key => '_session_id')

  def setup
    @integration_session = open_session(SessionApp)
  end
    
  class TestController < ActionController::Base

    def set_session_value
      session[:foo] = params[:foo] || "bar"
      head :ok
    end

    def get_session_value
      render :text => "foo: #{session[:foo].inspect}"
    end

    def get_session_id
      session[:foo]
      render :text => "#{request.session_options[:id]}"
    end

    def call_reset_session
      session[:foo]
      reset_session
      session[:foo] = "baz"
      head :ok
    end

    def rescue_action(e) raise end
  end
  
  def test_setting_and_getting_session_value
    with_test_route_set do
      get '/set_session_value'
      assert_response :success
      assert cookies['_session_id']

      get '/get_session_value'
      assert_response :success
      assert_equal 'foo: "bar"', response.body

      get '/set_session_value', :foo => "baz"
      assert_response :success
      assert cookies['_session_id']

      get '/get_session_value'
      assert_response :success
      assert_equal 'foo: "baz"', response.body
    end
  end

  def test_getting_nil_session_value
    with_test_route_set do
      get '/get_session_value'
      assert_response :success
      assert_equal 'foo: nil', response.body
    end
  end

  def test_setting_session_value_after_session_reset
    with_test_route_set do
      get '/set_session_value'
      assert_response :success
      assert cookies['_session_id']
      session_id = cookies['_session_id']

      get '/call_reset_session'
      assert_response :success
      assert_not_equal [], headers['Set-Cookie']

      get '/get_session_value'
      assert_response :success
      assert_equal 'foo: "baz"', response.body

      get '/get_session_id'
      assert_response :success
      assert_not_equal session_id, response.body
    end
  end

  def test_getting_session_id
    with_test_route_set do
      get '/set_session_value'
      assert_response :success
      assert cookies['_session_id']
      session_id = cookies['_session_id']

      get '/get_session_id'
      assert_response :success
      assert_equal session_id, response.body
    end
  end




  private
    def with_test_route_set
      with_routing do |set|
        set.draw do |map|
          map.with_options :controller => "full_stack_test/test" do |c|
            c.connect "/:action"
          end
        end
        yield
      end
    end
  
end



end
