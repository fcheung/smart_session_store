# An ActiveRecord class which corresponds to the database table
# +sessions+. Functions +find_session+, +create_session+,
# +update_session+ and +destroy+ constitute the interface to class
# +SmartSessionStore+.
module SmartSessionStore
  class SqlSession < ActiveRecord::Base
    self.table_name = 'sessions'
    # this class should not be reloaded
    def self.reloadable?
      false
    end

    # retrieve session data for a given +session_id+ from the database,
    #if lock is true, then lock the returned row
    # return nil if no such session exists
    def self.find_session(session_id, lock=false)
      find :first, :conditions => "session_id='#{session_id}'", :lock => lock
    end

    # create a new session with given +session_id+ and +data+
    def self.create_session(session_id, data)
      new(:session_id => session_id, :data => data)
    end

    # update session data and store it in the database
    def update_session(data)
      update_attribute('data', data)
    end
    
    # update session data using optimistic locking - return true on success, false if the record was stale
    def update_session_optimistically data
      update_attribute('data', data)
      true
    rescue ActiveRecord::StaleObjectError
      false
    end
    
    #find the session record by its primary key id as opposed to its session id
    def self.find_by_primary_id(primary_key_id, lock=false)
      if primary_key_id
        find primary_key_id, :lock => lock
      else
        nil
      end
    end
    
  end
end
