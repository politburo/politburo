require 'trollop'
require 'json'
require 'pathname'
require 'logger'
require 'foreman/process'

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
        opt :interactive, "Interactive pry console", :short => 'i'
        opt :color, "Use colored output", :default => true, :short => 'c'
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
      exit_success = true

      String.allow_colors = options[:color]
      if (options[:interactive])
        require 'pry'
        self.pry 
      else
        exit_success = runner.run
      end

      release

      exit_success
    end

    def root()
      @root ||= Politburo::DSL.define(envfile_contents)
    end

    def release()
      root.each { | r | r.release }
    end

    def resolved_targets
      Set.new(targets.map do | unresolved_target |
        resolved_set = root.find_all_by_attributes(full_name: "#{unresolved_target}")
        raise("Could not resolve target: '#{unresolved_target}'.") if resolved_set.empty?
        resolved_set.map(&:as_dependency)
      end.flatten)
    end

    def envfile_contents()
      @envfile_contents ||= File.open(options[:envfile], "r") { | f | f.read() }
    end

    def babushka_sources_path()
      result_path = Pathname.new(File.expand_path(options[:'babushka-sources-dir']))
      raise "Babushka sources directory: '#{result_path.to_s}' does not exist or isn't a directory" unless result_path.directory?
      result_path
    end

    def log()
      @log ||= ::Logger.new(STDOUT)
    end

    private

    def tasks_to_run
      @tasks_to_run ||= resolved_targets.map(&:to_task)
    end

    def runner
      @runner ||= Politburo::Dependencies::Runner.new(*tasks_to_run)
    end

  end
end