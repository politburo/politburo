require 'trollop'
require 'json'
require 'pathname'

module Politburo
  class CLI
    attr_reader :options
    attr_reader :targets

    def self.create(arguments)
      p = Trollop::Parser.new do
          version "politburo, version #{Politburo::VERSION}"
          banner <<-EOS
        Politburo - The Babushka-wielding DevOps orchestrator 

        Usage:
               politburo [options] resource[#state] [resource2[#state]]+
        where [options] are:
        EOS
        opt :envfile, "Use a different envfile", :short => 'e', :default => 'Envfile'
        opt :'babushka-sources-dir', "Use a different babushka sources dir", :short => 'b', :default => '~/.babushka/sources'
      end

      opts = Trollop::with_standard_exception_handling p do
        opts = p.parse arguments
        raise Trollop::HelpNeeded if arguments.empty? # show help screen

        opts
      end

      self.new(opts, arguments)
    end

    def initialize(options, targets)
      @options = options
      @targets = targets
    end

    def run()
      #puts JSON.pretty_generate(root)
      generate_to(target_generation_path.realpath)
    end

    def generate_to(target_dir)
      File.open(File.join(target_dir, 'politburo_generated_deps.rb'), "w") { | f | f.write(root.to_babushka_deps) }
    end

    def root()
      @root ||= Politburo::DSL.define(envfile_contents)
    end

    def envfile_contents()
      @envfile_contents ||= File.open(options[:envfile], "r") { | f | f.read() }
    end

    def babushka_sources_path()
      result_path = Pathname.new(File.expand_path(options[:'babushka-sources-dir']))
      raise "Babushka sources directory: '#{result_path.to_s}' does not exist or isn't a directory" unless result_path.directory?
      result_path
    end

    def target_generation_path()
      @target_generation_path ||= begin 
        target_generation_path = babushka_sources_path + "politburo-#{Time.now.to_i.to_s}"
        target_generation_path.mkdir
        raise "Could not create target generation path: '#{target_generation_path.realpath}'" unless target_generation_path.directory?
        target_generation_path
      end
    end

  end
end