module SessionSmarts
  def marshalize(data)
    Base64.encode64(Marshal.dump(data))
  end

  def unmarshalize(data)
    Marshal.load(Base64.decode64(data))
  end
  
  def save_session(session, data)
    original_data = unmarshalize(session.data)
    original_marshalled_data = session.data

    deleted_keys = original_data.keys - data.keys
    changed_keys = []
    data.each {|k,v| changed_keys << k if Marshal.dump( original_data[k]) != Marshal.dump( v)}
    
    return nil if changed_keys.empty? && deleted_keys.empty?

    SqlSession.transaction do
      fresh_session = session_class.find_session(session.session_id, true)
      if fresh_session && fresh_session.data != original_marshalled_data && fresh_data = unmarshalize(fresh_session.data)
        deleted_keys.each {|k| fresh_data.delete k}
        changed_keys.each {|k| fresh_data[k] = data[k]}
        data = fresh_data
        session = fresh_session
      end
      session.update_session(marshalize(data))
    end
    return data, session
  end
end

# This software is released under the MIT license
# Copyright (c) 2007-2009 Frederick Cheung

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
