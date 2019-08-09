require 'bundler'
require 'rake/testtask'
require 'rubocop/rake_task'

Bundler::GemHelper.install_tasks

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList["test/**/*_test.rb"]
  t.verbose = true
end

RuboCop::RakeTask.new

task default: [:rubocop, :test]
