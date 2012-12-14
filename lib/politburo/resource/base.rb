module Politburo
	module Resource
		class Base
			include Enumerable
			include Politburo::DSL::DslDefined
			include Politburo::Resource::Searchable
			include Politburo::Resource::HasStates

			attr_accessor :parent_resource
			attr_accessor :name
			attr_accessor :description

			attr_accessor_with_default(:log_level) { Logger::INFO }

			attr_accessor_with_default(:log_formatter) do
        task = self
				lambda do |severity, datetime, progname, msg|
            "#{datetime.to_s} #{severity.to_s.colorize( severity_color[severity.to_s.downcase.to_sym])}\t#{self.name.white}\t#{msg}\n"
        end
			end

			attr_accessor_with_default(:logger_output) { $stdout }

			attr_reader_with_default(:logger) do
				logger = Logger.new(self.logger_output)
        logger.level = self.log_level
        logger.formatter = self.log_formatter
        logger
			end

			requires :name

			has_state :defined

			has_state :starting => :defined
			has_state :started => :starting
			has_state :configuring => :started
			has_state :configured => :configuring
			has_state :ready => :configured

			has_state :stopping => :defined
			has_state :stopped => :stopping

			has_state :terminated => :stopped

			def initialize(attributes)
				update_attributes(attributes)
				parent_resource.children << self unless parent_resource.nil?
			end

			def children()
				@children ||= Set.new
			end

			def full_name
				parent_resource.nil? ? name : (parent_resource.name.empty? ? name : "#{parent_resource.full_name}:#{name}")
			end

			def as_dependency
				state(:ready)
			end

			def contained_searchables
				Set.new().merge(children).merge(states)
			end

			def release
				# To be overriden by subclasses
			end

			def each(&block)
				block.call(self)
				states.each(&block)
				children.each { | c | c.each(&block) } 
			end

			def add_dependency_on(target)
				state(:ready).add_dependency_on(target)
			end

      def severity_color()
        {
          debug: 37,
          info: 36,
          warn: 33,
          error: 31, }
      end			
		end

	end
end

