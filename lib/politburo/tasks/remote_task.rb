module Politburo
  module Tasks
    class RemoteTask
      include Politburo::DSL::DslDefined
      include Politburo::Dependencies::Task

      attr_accessor :node
      attr_accessor :command
      attr_accessor :met_test

      requires :command
      requires :met_test

      def initialize(attributes)
        update_attributes(attributes)

        validate!
      end

    end
  end
end

