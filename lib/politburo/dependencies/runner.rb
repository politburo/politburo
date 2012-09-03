module Politburo
  module Dependencies
    class Runner
      attr_reader :start_with

      def initialize(*tasks_to_run)
        @start_with = tasks_to_run
      end

    end
  end
end

