== SmartSessionStore

A session store that avoids the pitfalls usually associated with concurrent access to the session (see http://www.texperts.com/2007/05/01/race-conditions-in-rails-sessions-and-how-to-fix-them/)

Derived from SqlSessionStore, see http://railsexpress.de/blog/articles/2005/12/19/roll-your-own-sql-session-store

== Step 1

Generate your sessions table using rake db:sessions:create

== Step 2

Add the code below in an initializer
  ActionController::Base.session_store = :smart_session_store

Finally, depending on your database type, add

    SmartSessionStore.session_class = MysqlSession
or

    SmartSessionStore.session_class = PostgresqlSession
or
    SmartSessionStore.session_class = SqliteSession

after the initializer section in environment.rb

== Step 3 (optional)

If you want to use a database separate from your default one to store
your sessions, specify a configuration in your database.yml file (say
sessions), and establish the connection on SqlSession in
environment.rb:

   SqlSession.establish_connection :sessions

== Testing

To run tests with a certain database, set the DATABASE attribute.
You may need to configure the database.yml or your database server.

For example:

   rake test    # defaults to mysql
   rake test DATABASE=postgresql

== IMPORTANT NOTES

1. You will need the binary drivers for Mysql or Postgresql.
   These have been verified to work:

   * ruby-postgres (0.7.1.2005.12.21) with PostgreSQL 8.1
   * postgres (0.7.9.2008.01.28) with PostgreSQL 8.3
   * pg (0.7.9.2008.10.13) with PostgreSQL 8.3
   * ruby-mysql 2.7.1 with Mysql 4.1
   * ruby-mysql 2.7.2 with Mysql 5.0

2. Tests have been done with SqlLiteSession, SqlSession, PostgresqlSession
   and MysqlSession. Feedback would be very much appreciated.
