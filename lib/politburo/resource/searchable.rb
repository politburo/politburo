module Politburo

	module Resource

		module Searchable
			def self.included(base)
				base.extend(ClassMethods)
			end

			def find_all_by_attributes(attributes)
				found = Set.new
				found << self if matches(self, attributes)

				unless children.nil? 
					children.each do | child |
						if child.respond_to?(:find_all_by_attributes) 
							found.merge(child.find_all_by_attributes(attributes))
						else
							found << child if matches(child, attributes)
						end
					end
				end

				found
			end

			private

			def matches(obj, attributes)
				attributes.each_pair do | attr_name, match_to |
					value = obj.respond_to?(attr_name.to_sym) ? obj.send(attr_name.to_sym) : nil

					if match_to.is_a?(Proc)
						return false unless match_to.call(obj, value)
					else
						return false unless match_to.eql?(value)
					end
				end

				true
			end

			module ClassMethods
			end

		end

	end

end