module Politburo

	module Resource

		module Searchable
			def self.included(base)
				base.extend(ClassMethods)
			end

			def find_all_by_attributes(attributes)
				found = Set.new
				found << self if Searchable.matches?(self, attributes)

				unless contained_searchables.nil? 
					contained_searchables.each do | contained |
						if contained.respond_to?(:find_all_by_attributes) 
							found.merge(contained.find_all_by_attributes(attributes))
						else
							found << contained if Searchable.matches?(contained, attributes)
						end
					end
				end

				found
			end

			def find_direct_children_by_attributes(attributes)
				contained_searchables.nil? ? Set.new : Set.new(contained_searchables.select { | contained | contained if Searchable.matches?(contained, attributes) })
			end

			def root()
				parent_resource.nil? ? self : parent_resource.root
			end

			def self.matches?(obj, attributes)
				attributes.each_pair do | attr_name, match_to |
					value = obj.respond_to?(attr_name.to_sym) ? obj.send(attr_name.to_sym) : nil

					if match_to.is_a?(Proc)
						return false unless match_to.call(obj, attr_name, value)
					elsif match_to.is_a?(Regexp)
						return false unless match_to.match(value.to_s)
					else
						return false unless match_to.eql?(value) or match_to.to_s.eql?(value.to_s)
					end
				end

				true
			end



			module ClassMethods

			end

		end

	end

end