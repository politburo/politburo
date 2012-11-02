module Politburo
  module Tasks
    class RemoteTask
      include Politburo::DSL::DslDefined
      include Politburo::Dependencies::Task

      attr_accessor :node
      attr_accessor :command
      attr_accessor :met_test_command

      requires :command
      requires :met_test_command

      def initialize(attributes)
        update_attributes(attributes)

        validate!
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

