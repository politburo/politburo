module Politburo
  module Resource
    class StateTask
      include Politburo::Dependencies::Task
      include Politburo::DSL::DslDefined
      include Politburo::Resource::HasDependencies
      include Politburo::Resource::Searchable

      attr_accessor :resource_state
      attr_accessor :prerequisites

      attr_writer :name

      requires :resource_state
      requires :prerequisites

      def initialize(attributes)
        update_attributes(attributes)

        resource_state.tasks << self

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

      def dependencies=(new_deps)
        @dependencies ||= new_deps
      end

      def prerequisites
        dependencies.map(&:to_task)
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

      def logger_display_name
        "#{Time.now} #{resource_state.full_name.yellow} #{name.green}"
      end

      def stdout_console_prefix
        "#{Time.now} #{name.yellow} #{ "#{resource.user}@#{resource.host}".green } | "
      end

      def stderr_console_prefix
        "#{Time.now} #{name.yellow} #{ "#{resource.user}@#{resource.host}".red } ! "
      end

      def stdout_console
        @stdout_console ||= begin 
          task = self
          Politburo::Support::Consoles.instance.create_console() { | s | "#{task.stdout_console_prefix}#{s}" }
        end
      end

      def stderr_console
        @stderr_console ||= begin 
          task = self
          Politburo::Support::Consoles.instance.create_console() { | s | "#{task.stderr_console_prefix}#{s}" }
        end
      end

    end

  end
end
