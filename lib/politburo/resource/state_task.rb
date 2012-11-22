module Politburo
  module Resource
    class StateTask
      include Politburo::Dependencies::Task
      include Politburo::DSL::DslDefined

      attr_accessor :resource_state
      attr_accessor :prerequisites

      attr_writer :name

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
        @name ||= resource_state.full_name
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

      def logger
        @logger ||= begin 
          logger = Logger.new(STDOUT)
          task = self
          logger.level = Logger::INFO
          logger.formatter = proc do |severity, datetime, progname, msg|
            "#{datetime.to_s.green} #{resource_state.full_name.yellow} #{task.name.green}\t#{msg}\n"
          end
          logger
        end
      end

    end

  end
end
