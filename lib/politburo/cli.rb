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
      generate_to_path = target_generation_path

      begin
        generate_to(generate_to_path.realpath)
        run_babushka
      ensure
        generate_to_path.rmtree
        log.debug("Cleaned up target generation path: '#{generate_to_path.realdirpath}'")
      end
    end

    def generate_to(target_dir)
      target_deps_file = File.join(target_dir, 'politburo_generated_deps.rb')
      File.open(target_deps_file, "w") { | f | f.write(root.to_babushka_deps) }
      log.debug("Generated deps to: '#{target_deps_file}'")
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

    def target_generation_dirname
      @target_generation_dirname ||= "politburo-run-#{Time.now.to_i.to_s}"
    end

    def target_generation_path()
      @target_generation_path ||= begin 
        target_generation_path = babushka_sources_path + target_generation_dirname
        target_generation_path.mkdir
        raise "Could not create target generation path: '#{target_generation_path.realpath}'" unless target_generation_path.directory?
        log.debug("Created target generation path: '#{target_generation_path.realpath}' ")
        target_generation_path
      end
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