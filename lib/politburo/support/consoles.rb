require 'singleton'

module Politburo
  module Support
    class Consoles
      include Singleton

      def initialize
        watch_for_output
      end

      def create_console(&block)
        console = Console.new(&block)

        items << console
        @consoles_by_readers = nil

        console
      end

      def output
        @output ||= $stdout
      end

      def items
        @items ||= []
      end

      def readers
        items.map(&:reader)
      end

      def consoles_by_readers
        @consoles_by_readers ||= Hash[ items.map { | console | [ console.reader, console ] } ]
      end

      def watch_for_output
        Thread.new do
          begin
            loop do
              watch_for_output_step
            end
          rescue Exception => ex
            puts ex.message
            puts ex.backtrace
          end
        end
      end

      def output_with_mutex(console, data)
        @mutex.synchronize do
          output.puts console.format(data)
        end
      end

      def watch_for_output_step
        io = IO.select(readers, nil, nil, 30)
        (io.nil? ? [] : io.first).each do |reader|
          data = reader.gets
          output_with_mutex consoles_by_readers[reader], data
        end
      end

    end
  end
end