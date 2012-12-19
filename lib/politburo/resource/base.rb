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

			def log_formatter
				@log_formatter ||= lambda do |severity, datetime, progname, msg|
            "#{datetime.to_s} #{self.full_name.to_s.colorize( severity_color[severity.to_s.downcase.to_sym])}\t#{msg}\n"
        end
			end

			def each(&block)
				block.call(self)
				states.each(&block)
				children.each { | c | c.each(&block) } 
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

