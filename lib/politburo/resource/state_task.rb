module Politburo
  module Resource
    class StateTask
      include Politburo::Dependencies::Task

      attr_reader :resource_state

      def initialize(resource_state)
        @resource_state = resource_state
      end

      def name 
        resource_state.full_name
      end

      def resource
        resource_state.resource
      end

      def prerequisites
        resource_state.dependencies.map(&:to_task)
      end

      def met?
        true
      end
    end

  end
end
