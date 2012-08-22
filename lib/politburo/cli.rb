require 'trollop'

module Politburo
  module CLI

    def self.start(arguments)
      p = Trollop::Parser.new do
          version "politburo, version #{Politburo::VERSION}"
          banner <<-EOS
        Politburo - The Babushka-wielding DevOps orchestrator 

        Usage:
               politburo [options] resource[#state] [resource2[#state]]+
        where [options] are:
        EOS
        opt :pretend, "Pretend to run, but don't actually execute any remote deps", :short => 'p'
      end

      opts = Trollop::with_standard_exception_handling p do
        opts = p.parse arguments
        raise Trollop::HelpNeeded if arguments.empty? # show help screen

        opts
      end

      puts "Options: #{opts.inspect}"
      puts "Target resource(s)/state(s): #{arguments.inspect}"

    end

  end
end