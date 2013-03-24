
require 'base64'
# +SmartSessionStore+ is a session store that strives to correctly handle session storage in the face of multiple
# concurrent actions accessing the session. It is derived from Stephen Kaes' +SqlSessionStore+, a stripped down,
# optimized for speed version of class +ActiveRecordStore+.
#
module SmartSessionStore

  class Store < ActionController::Session::AbstractStore
    include SmartSessionStore::SessionSmarts
    
    # The class to be used for creating, retrieving and updating sessions.
    # Defaults to SmartSessionStore::Session, which is derived from +ActiveRecord::Base+.
    #
    # In order to achieve acceptable performance you should implement
    # your own session class, similar to the one provided for Myqsl.
    #
    # Only functions +find_session+, +create_session+,
    # +update_session+ and +destroy+ are required. See file +mysql_session.rb+.

    cattr_accessor :session_class
    @@session_class = SmartSessionStore::SqlSession

    SESSION_RECORD_KEY = 'rack.session.record'.freeze
      
    private
    
    def get_session(env, sid)
      ActiveRecord::Base.silence do
        sid ||= generate_sid
        session = find_session(sid)
        env[SESSION_RECORD_KEY] = session
        [sid, unmarshalize(session.data)]
      end
    end

    def set_session(env, sid, session_data)
      ActiveRecord::Base.silence do
        record = get_session_model(env, sid)

        data, session = save_session(record, session_data)
        env[SESSION_RECORD_KEY] = session
      end

      return sid
    end

    def get_session_model(env, sid)
      if env[ENV_SESSION_OPTIONS_KEY][:id].nil?
        env[SESSION_RECORD_KEY] = find_session(sid)
      else
        env[SESSION_RECORD_KEY] ||= find_session(sid)
      end
    end
    
    def find_session(id)
      @@session_class.find_session(id) ||
        @@session_class.create_session(id, marshalize({}))
    end
    
    # Rails 2.3.14 needs this
    def destroy(env)
      if (sid = current_session_id(env)).present? && session = find_session(sid)
        session.destroy
      end
    end
  end
end
