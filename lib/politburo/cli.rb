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
    end

    def root()
      @root ||= Politburo::DSL.define(envfile_contents)
    end

    def resolved_targets
      targets.map do | unresolved_target |
        resolved_set = root.find_all_by_attributes(full_name: "#{unresolved_target}")
        raise("Could not resolve target: '#{unresolved_target}'.") if resolved_set.empty?
        resolved_set.map(&:to_state)
      end.flatten 
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

    def run_babushka
        command = "babushka #{target_generation_dirname}:All#ready"
        log.debug("About to execute command: '#{command}'")
        process = Foreman::Process.new(command)
        process.run
        Process.waitall
        log.info("Run complete.")
    end
  end
end