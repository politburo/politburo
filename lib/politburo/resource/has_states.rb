module Politburo

	module Resource

		module HasStates
			include ::Politburo::DSL::DslDefined
			include ::Politburo::Resource::HasHierarchy
			include ::Politburo::Resource::Searchable

			def self.included(base)
				base.extend(ClassMethods)
			end

			def states(attributes = {}) 
				find_direct_children_by_attributes(attributes.merge(class: Politburo::Resource::State))
			end

			def state(name)
				found = states.find_all { | state | Searchable.matches?(state, name: name) } 
				raise "No state: #{name} found on '#{self.full_name}'" if found.empty?
				raise "More than one state found with name: #{name} on '#{self.full_name}'. #{found.map(&:inspect).join(", ")}" if (found.length > 1)

				found.first
			end

			module ClassMethods

				def has_state(state_definition)
					implies &make_state_proc(state_definition)
				end

				private

				def make_state_proc(state_definition)
					state_name, dependencies = unpack_state_definition(state_definition)

					Proc.new do 
						context = self
						state = state(state_name) do
							dependencies.each do | dep |
								depends_on state(name: dep, parent_resource: context.receiver)
							end
						end
					end
				end

				def unpack_state_definition(state_definition)
					state_name = nil
					dependencies = []

					if state_definition.is_a?(Hash) 
						raise "Must have one, and only one key->value pair in state definition" unless state_definition.length == 1
						state_definition.each_pair do | key, value | 
							state_name = key
							dependencies = [ value ].flatten
						end
					else
						state_name = state_definition
					end				
					
					return state_name, dependencies	
				end

			end

		end

	end

end