require 'active_record'
require 'base64'
require 'pp'
# +SmartSessionStore+ is a session store that strives to correctly handle session storage in the face of multiple
# concurrent actions accessing the session. It is derived from Stephen Kaes' +SqlSessionStore+, a stripped down,
# optimized for speed version of class +ActiveRecordStore+.
#
# This version is the one used for rails > 2.3
class SmartSessionStore < ActionController::Session::AbstractStore
  include SessionSmarts
  
  # The class to be used for creating, retrieving and updating sessions.
  # Defaults to SmartSessionStore::Session, which is derived from +ActiveRecord::Base+.
  #
  # In order to achieve acceptable performance you should implement
  # your own session class, similar to the one provided for Myqsl.
  #
  # Only functions +find_session+, +create_session+,
  # +update_session+ and +destroy+ are required. See file +mysql_session.rb+.

  cattr_accessor :session_class
  @@session_class = SqlSession

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

    return true
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
    
end

__END__

# This software is released under the MIT license
# Copyright (c) 2007-2009 Frederick Cheung
# Copyright (c) 2005,2006 Stefan Kaes

# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:

# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

