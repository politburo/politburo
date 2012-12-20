require "bundler/gem_tasks"
require 'rspec/core/rake_task'
require_relative 'lib/politburo/support/colorize'

RSpec::Core::RakeTask.new(:spec) do | spec |
  spec.rspec_opts = %w(--options .rspec-with-end-to-end)
end

task :default => "cover_me:report"

String.allow_colors = true

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
    coverage_threshold = 99.77

    colored_coverage_s = "#{coverage}%".send(coverage < coverage_threshold ? :red : :green)

    puts "Coverage at: #{ colored_coverage_s }"
    raise "Not enough coverage, #{colored_coverage_s} is less than current ratchet threshold of #{ "#{coverage_threshold}%".green }" if coverage < coverage_threshold
  end

end

task :test do
  Rake::Task['cover_me:report'].invoke
end

task :clean do
  puts "Cleaning up coverage data..."
  FileUtils.rm_rf('coverage')
  FileUtils.rm_rf('coverage.data')
end

task :spec => :clean do
  Rake::Task['cover_me:report'].invoke
end
