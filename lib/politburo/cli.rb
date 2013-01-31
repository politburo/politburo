require 'trollop'
require 'json'
require 'pathname'
require 'logger'

module Politburo
  class CLI
    attr_reader :options
    attr_reader :targets

    def self.default_plugins
      @default_plugins ||= Set.new([ Politburo::Plugins::Cloud::Plugin, Politburo::Plugins::Babushka::Plugin ])
    end

    def self.create(arguments)
      p = Trollop::Parser.new do
          version "politburo, version #{Politburo::VERSION}"
          banner <<-EOS
        Politburo - The Developer's DevOps orchestrator 

        Usage:
               politburo [options] resource[#state] [resource2[#state]]+
        where [options] are:
        EOS
        opt :interactive, "Interactive pry console", :short => 'i'
        opt :color, "Use colored output", :default => true, :short => 'c'
        opt :envfile, "Use a different envfile", :short => 'e', :default => 'Envfile'
        opt :plugins, "Use different default plugins (comma separated)", :default => Politburo::CLI.default_plugins.map(&:to_s).join(', ')
        opt :'private-keys-dir', "Use a different private keys dir", :short => 'b', :default => '.ssh'
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
        pry
      else
        exit_success = runner.run
      end

      root.logger.debug("About to release resources...")
      release

      root.logger.info("Run completed successfully: #{resolved_targets.map(&:full_name).join(", ")} satisfied.") if exit_success

      exit_success
    end

    def root()
      _cli = self
      @root ||= Politburo::DSL.define(envfile_contents, plugins) {
        self.cli = _cli
      }
    end

    def context
      root.context
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

    def envfile_path
      @envfile_path ||= Pathname.new(options[:envfile])
    end

    def envfile_contents()
      @envfile_contents ||= envfile_path.read 
    end

    def private_keys_path()
      result_path = Pathname.new(File.expand_path(options[:'private-keys-dir']))
      raise "Key files directory: '#{result_path.to_s}' does not exist or isn't a directory" unless result_path.directory?
      result_path
    end

    def plugins
      @plugins ||= begin
        options[:plugins].nil? ? [] : options[:plugins].split(/[\s,]+/).map { | plugin_class_name | eval(plugin_class_name) }
      end
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