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
        @command = Politburo::Tasks::RemoteCommand.repack(command_obj_or_string)
      end

      def met_test_command=(command_obj_or_string)
        @met_test_command = Politburo::Tasks::RemoteCommand.repack(command_obj_or_string)
      end

      private 

      def execute_command(cmd)
        logger.info("Executing '#{cmd}' on #{node.user}@#{node.host} (#{node.name})...")
        result = nil
        channel = node.session.open_channel do | channel |
          result = cmd.execute(channel)
        end
        channel.wait
        logger.debug("Finished executing '#{cmd}' on #{node.user}@#{node.host} (#{node.name})...")
        result
      end

    end


  end
end

