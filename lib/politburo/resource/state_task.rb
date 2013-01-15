module Politburo
  module Resource
    class StateTask
      include Politburo::Dependencies::Task
      include Politburo::DSL::DslDefined
      include Politburo::Resource::BelongsToHierarchy
      include Politburo::Resource::HasDependencies
      include Politburo::Resource::Searchable

      attr_accessor :prerequisites

      attr_writer :name

      requires :prerequisites

      def initialize(attributes)
        update_attributes(attributes)
      end

      def resource_state
        parent_resource
      end

      def name 
        @name ||= resource_state.full_name
      end

      def resource
        resource_state.parent_resource
      end

      def contained_searchables
        Set.new
      end

      def release
      end

      def dependencies=(new_deps)
        @dependencies ||= new_deps
      end

      def prerequisites
        Set.new(resource_state.state_dependencies.map(&:to_task) + dependencies.map(&:to_task))
      end

      def as_dependency 
        self
      end

      def to_task
        self
      end

      def met?(verification = false)
        true
      end

      def log_formatter
        @log_formatter ||= lambda do |severity, datetime, progname, msg|
          "#{console_prefix(datetime)} #{msg}\n"
        end
      end

      def console_prefix(datetime)
        "#{datetime.to_s} #{self.resource_state.full_name.to_s.white} #{self.name.cyan}"
      end


      def stdout_console_prefix
        "#{self.console_prefix(Time.now)} #{ "#{resource.user}@#{resource.host}".cyan } | "
      end

      def stderr_console_prefix
        "#{self.console_prefix(Time.now)} #{ "#{resource.user}@#{resource.host}".red } ! "
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
