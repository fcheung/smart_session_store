require File.join(File.dirname(__FILE__), '../test_helper')

SmartSession::SqlSession.table_name = "sessions_custom"

require File.join(File.dirname(__FILE__), 'smart_session_test')
