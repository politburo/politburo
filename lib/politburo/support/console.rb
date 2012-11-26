module Politburo
  module Support
    class Console

      attr_reader :prefix

      attr_reader :reader
      attr_reader :writer

      attr_reader :format_block

      def initialize(&format_block)
        @format_block = format_block if block_given?

        @reader, @writer = IO.method(:pipe).arity.zero? ? IO.pipe : IO.pipe("BINARY")
      end

      def format_block
        @format_block ||= lambda { | s | s }
      end

      def format(line)
        format_block.call(line)
      end

      def close
        writer.flush
        writer.close
        reader.close
      end

    end
  end
end
