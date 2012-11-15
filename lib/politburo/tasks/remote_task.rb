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

      def met?
        node.session.open_channel do | channel |
          met_test_command.execute(channel)
        end
      end

      def meet
        node.session.open_channel do | channel |
          command.execute(channel)
        end
      end
    end


  end
end

