module Politburo
  module Support
    class Console

      attr_reader :prefix

      attr_reader :reader
      attr_reader :writer

      def initialize(prefix)
        @prefix = prefix

        @reader, @writer = IO.method(:pipe).arity.zero? ? IO.pipe : IO.pipe("BINARY")
      end

    end
  end
end
