module Politburo
	module Resource
		class Base
			include Politburo::DSL::DslDefined
			include Politburo::Resource::HasHierarchy
			include Politburo::Resource::Searchable
			include Politburo::Resource::HasStates

			attr_accessor :name
			attr_accessor :description

			requires :name

			has_state :defined

			has_state :created => :defined
			has_state :starting => :created
			has_state :started => :starting
			has_state :configuring => :started
			has_state :configured => :configuring
			has_state :ready => :configured

			has_state :stopping => :defined
			has_state :stopped => :stopping

			has_state :terminated => :stopped

			def initialize(attributes)
				update_attributes(attributes)
			end

			def applied_roles
				@applied_roles ||= Set.new
			end

			def as_dependency
				state(:ready)
			end

			def release
				# To be overriden by subclasses
			end

			def inspect
				"<#{self.class.to_s}:#{"0x%x" % self.__id__} \"#{full_name}\">"
			end

			def to_s
				"<#{self.class.to_s}:#{"0x%x" % self.__id__} \"#{full_name}\">"
			end

			def log_formatter
				@log_formatter ||= lambda do |severity, datetime, progname, msg|
            "#{datetime.to_s} #{self.full_name.to_s.colorize( severity_color[severity.to_s.downcase.to_sym])}\t#{msg}\n"
        end
			end

			def add_dependency_on(target)
				if target.respond_to?(:states)
					states.each do | source_state |
						source_state.add_dependency_on(target.state(source_state.name))
					end
				else
					ready_state = state(:ready)
					ready_state.add_dependency_on(target)
				end
			end

		end

	end
end

