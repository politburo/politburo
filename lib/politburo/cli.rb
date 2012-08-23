require 'trollop'

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
        opt :pretend, "Pretend to run, but don't actually execute any remote deps", :short => 'p'
      end

      opts = Trollop::with_standard_exception_handling p do
        opts = p.parse arguments
        raise Trollop::HelpNeeded if arguments.empty? # show help screen

        opts
      end

      cli = self.new(opts, arguments)

      cli.run()

      cli
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

    def envfile_contents()
      @envfile_contents ||= File.open(options[:envfile], "r") { | f | f.read() }
    end

  end
end