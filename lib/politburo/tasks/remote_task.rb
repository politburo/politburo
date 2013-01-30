module Politburo
  module Tasks
    class RemoteTask < Politburo::Resource::StateTask

      attr_reader :command
      attr_reader :met_test_command

      requires :command
      requires :met_test_command

      attr_with_default(:name) { "RemoteTask { command: '#{command}', met? '#{met_test_command}' }" }

      def node
        self.resource
      end

      def met?(verification = false)
        execute_command(met_test_command)
      end

      def meet(try = 0)
        execute_command(command)
      end

      def command=(command_obj_or_string)
        @command = Politburo::Tasks::RemoteCommand.repack(command_obj_or_string, command_logger)
      end

      def met_test_command=(command_obj_or_string)
        @met_test_command = Politburo::Tasks::RemoteCommand.repack(command_obj_or_string, command_logger)
      end

      def command_log_formatter
        @command_log_formatter ||= lambda do |severity, datetime, progname, msg|
          "#{colorize_by_severity(datetime, severity)} #{node.full_name}\t#{colorize_by_severity(msg, severity)}\n"
        end
      end

      attr_with_default(:command_logger) { 
        cmd_logger = Logger.new(logger_output)
        cmd_logger.level = log_level
        cmd_logger.formatter = command_log_formatter
        cmd_logger        
      }

      private 

      def execute_command(cmd)
        logger.info("Remote executing '#{cmd.to_s.cyan}' on '#{node.full_name.cyan}' (#{"#{node.user}@#{node.host}".cyan})...")
        result = nil
        channel = node.session_pool.take do | session | 
          session.open_channel do | channel |
            result = cmd.execute(channel)
          end
        end
        channel.wait
        logger.debug("Execution result: #{cmd.execution_result}.")
        result
      end

    end


  end
end

