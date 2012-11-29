require 'cover_me'

CoverMe.config do |c|
  # where is your project's root:
  c.project.root = File.expand_path(".").to_s
  puts "Project root: ", c.project.root
  
end