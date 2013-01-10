module Politburo

	module Resource

		module HasStates
			include ::Politburo::Resource::HasHierarchy
			include ::Politburo::Resource::Searchable

			def self.included(base)
				base.extend(ClassMethods)
			end

			def states() 
				if @states.nil? 
					@states ||= Set.new()

					has_state_obj = self

					klazz = self.class
					until (klazz.nil?)
						if (klazz.respond_to?(:state_definitions))
							klazz.state_definitions.each do | state_definition | 
								has_state_obj.define_state(state_definition)
							end
						end

						klazz = klazz.superclass
					end

				end

				@states
			end

			def state(name)
				found = states.find_all { | state | Searchable.matches?(state, name: name) } 
				raise "No state: #{name} found on '#{self.name}'" if found.empty?
				raise "More than one state found with name: #{name} on '#{self.to_s}'. #{found.map(&:inspect).join(", ")}" if (found.length > 1)

				found.first
			end

			def find_states(attributes)
				find_direct_children_by_attributes(attributes.merge(:parent_resource => self, :class => Politburo::Resource::State))
			end

			def define_state(state_definition)
				state_name = nil
				dependencies = []

				if state_definition.is_a?(Hash) 
					raise "Must have one, and only one key->value pair in state definition" unless state_definition.length == 1
					state_definition.each_pair do | key, value | 
						state_name = key
						dependencies = [ value ].flatten.map { | dependent_state_name | state(dependent_state_name) }
					end
				else
					state_name = state_definition
				end

				found = find_states(name: state_name)
				raise "More than one existing state found with name: #{name}" if (found.length > 1)

				state = found.first || begin 
					state = Politburo::Resource::State.new(name: state_name)
					
					add_child(state)
					states << state

					state
				end

				state.dependencies.push(*dependencies)

				state
			end

			module ClassMethods

				def has_state(state_definition)
					state_definitions << state_definition
				end

				def state_definitions
					@state_definitions ||= []
				end
			end

		end

	end

end