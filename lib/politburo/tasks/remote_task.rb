module Politburo
  module Tasks
    class RemoteTask < Politburo::Resource::StateTask

      attr_reader :command
      attr_reader :met_test_command

      requires :command
      requires :met_test_command

      def node
        self.resource
      end

      def name 
        @name ||= "RemoteTask { command: '#{command}', met? '#{met_test_command}' }"
      end

      def met?
        execute_command(met_test_command)
      end

      def meet
        execute_command(command)
      end

      def command=(command_obj_or_string)
        @command = Politburo::Tasks::RemoteCommand.repack(command_obj_or_string, nil, nil, stdout_console.writer, stderr_console.writer)
      end

      def met_test_command=(command_obj_or_string)
        @met_test_command = Politburo::Tasks::RemoteCommand.repack(command_obj_or_string, nil, nil, stdout_console.writer, stderr_console.writer)
      end

      private 

      def execute_command(cmd)
        logger.info("Remote executing '#{cmd}' on '#{node.name}' (#{node.user}@#{node.host})...")
        result = nil
        channel = node.session.open_channel do | channel |
          result = cmd.execute(channel)
        end
        channel.wait
        logger.debug("Execution result: #{cmd.execution_result}.")
        result
      end

    end


  end
end

