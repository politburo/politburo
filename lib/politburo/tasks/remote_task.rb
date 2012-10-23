module Politburo
  module Tasks
    class RemoteTask
      include Politburo::Dependencies::Task

      attr_reader :node

      def initialize(node) 
        @node = node
      end
    end
  end
end

