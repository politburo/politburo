module Politburo
  module Support
    module HasLogger
      include Politburo::Support::AccessorWithDefault
      def self.included(base)
        base.extend(ClassMethods)
      end

      attr_accessor_with_default(:log_level) { Logger::INFO }
      attr_accessor_with_default(:logger_output) { $stdout }

      attr_accessor_with_default(:log_formatter) do
        lambda { |severity, datetime, progname, msg| "#{datetime.to_s} #{severity.to_s.colorize( self.severity_color[severity.to_s.downcase.to_sym])}\t#{msg}\n" }
      end

      attr_reader_with_default(:logger) do
        logger = Logger.new(self.logger_output)
        logger.level = self.log_level
        logger.formatter = self.log_formatter
        logger
      end

      def severity_color()
        {
          debug: 37,
          info: 36,
          warn: 33,
          error: 31, 
        }
      end

      def colorize_by_severity(string, severity)
        string.to_s.colorize( self.severity_color[severity.to_s.downcase.to_sym] )
      end


      module ClassMethods
      end
    end
  end
end
