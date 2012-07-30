module Politburo
	module Resource
		class State
			include ::Politburo::DSL::DslDefined

			attr_reader :resource
			attr_accessor :name

			requires :resource
			requires :name

			def initialize(attributes)
				update_attributes(attributes)
				resource.states << self
			end

			def dependencies()
				@dependencies ||= []
			end

			def dependent_on?(another_state)
				dependencies.include?(another_state)
			end

			def add_dependency_on(state_or_resource)
				state = nil
				if state_or_resource.is_a?(Politburo::Resource::State)
					state = state_or_resource
				elsif state_or_resource.is_a?(Politburo::Resource::HasStates)
					state = state_or_resource.state(:ready)
				else
					raise "Can only become dependent on state or resource. #{state_or_resource.inspect} is neither."
				end

				dependencies << state
			end

			private

			attr_writer :resource
		end
	end
end

