require 'rake'
require 'rake/testtask'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the smart_session_store plugin.'
task :test => ['test:default', 'test:custom']

Rake::TestTask.new('test:custom') do |t|
  t.libs << 'lib'
  t.pattern = 'test/unit/custom_table_name_test.rb'
  t.verbose = true
end

Rake::TestTask.new('test:default') do |t|
  t.libs << 'lib'
  t.pattern = 'test/unit/smart_session_test.rb'
  t.verbose = true
end
