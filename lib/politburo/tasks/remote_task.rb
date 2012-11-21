module Politburo
  module Tasks
    class RemoteTask < Politburo::Resource::StateTask

      attr_accessor :command
      attr_accessor :met_test_command

      requires :command
      requires :met_test_command

      def node
        self.resource
      end

      def name 
        "RemoteTask { command: '#{command}', met_test_command: '#{met_test_command}' }"
      end

      def met?
        execute_command(met_test_command)
      end

      def meet
        execute_command(command)
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

