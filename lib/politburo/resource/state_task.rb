module Politburo
  module Resource
    class StateTask
      include Politburo::Dependencies::Task
      include Politburo::DSL::DslDefined

      attr_accessor :resource_state
      attr_accessor :prerequisites

      requires :resource_state
      requires :prerequisites

      def initialize(attributes)
        update_attributes(attributes)

        validate!
      end

      def parent_resource=(resource)
        self.resource_state= resource
      end

      def parent_resource()
        self.resource_state
      end

      def name 
        resource_state.full_name
      end

      def resource
        resource_state.resource
      end

      def as_dependency 
        self
      end

      def to_task
        self
      end

      def met?
        true
      end
    end

  end
end
