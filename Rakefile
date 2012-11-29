require "bundler/gem_tasks"
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :default => "cover_me:report"

namespace :cover_me do

  desc "Generates and opens code coverage report."
  task :report => :spec do
    require 'cover_me'
    CoverMe.config { | c | c.at_exit = Proc.new {} }
    CoverMe.complete!

    processor = CoverMe.complete!

    match = /<div id='big_total' .*>(.*)%<\/div>/.match(File.open("coverage/index.html", "r").read)
    raise "Couldn't figure out coverage" if match.nil?

    coverage = match[1].to_f

    puts "Coverage at: #{coverage}"
    raise "Not enough coverage: #{coverage}" if coverage < 99.35
  end

end

task :test do
  Rake::Task['cover_me:report'].invoke
end

task :spec do
  Rake::Task['cover_me:report'].invoke
end
