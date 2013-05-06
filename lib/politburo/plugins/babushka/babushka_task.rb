require 'pry'
require 'shellwords'

module Politburo
  module Plugins
    module Babushka
      class BabushkaTask < Politburo::Tasks::RemoteTask

        implies do

          containing_node do
              state(:configured) {
                remote_task(name: 'install babushka', command: 'sudo sh -c "`curl https://babushka.me/up`"', met_test_command: 'which babushka') { }
              }
          end

          depends_on remote_task('install babushka')
        end

        requires :dep
        attr_accessor :dep

        attr_with_default(:command) { build_command }
        attr_with_default(:met_test_command) { Politburo::Tasks::RemoteCommand.repack("babushka meet #{dep} --dry-run", command_logger) }

        attr_with_default(:args) { {} } 

        def default_task_name
          "babushka #{dep}"
        end

        private 

        def build_command
          args_s = args.each_pair.map { | arg_name, value | "#{arg_name}=#{value.to_s.shellescape}" }.join(" ")

          Politburo::Tasks::RemoteCommand.repack("babushka meet #{dep} #{args_s}", command_logger)
        end
      end
    end
  end
end
