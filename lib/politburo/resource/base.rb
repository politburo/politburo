module Politburo
	module Resource
		class Base
			include Enumerable
			include Politburo::DSL::DslDefined
			include Politburo::Resource::Searchable
			include Politburo::Resource::HasStates

			attr_reader :parent_resource

			attr_accessor :name

			requires :name

			has_state :defined
			has_state :starting => :defined
			has_state :started => :starting
			has_state :configuring => :started
			has_state :configured => :configuring
			has_state :ready => :configured

			def initialize(attributes)
				update_attributes(attributes)
				parent_resource.children << self unless parent_resource.nil?
			end

			def children()
				@children ||= Set.new
			end

			def root()
				parent_resource.nil? ? self : parent_resource.root
			end

			def full_name
				parent_resource.nil? ? name : "#{parent_resource.full_name}/#{name}"
			end

			def contained_searchables
				Set.new().merge(children).merge(states)
			end

			def each(&block)
				block.call(self)
				states.each(&block)
				children.each { | c | c.each(&block) } 
			end

			def add_dependency_on(target)
				state(:ready).add_dependency_on(target)
			end

			def to_babushka_deps()
				self.map() { | s | s.to_babushka_deps unless s == self }.join("\n")
			end

			def to_json_hash()
				{
					name: name,
					states: states.to_a,
					children: children.to_a,
				}
			end

			def to_json(*args) 
				to_json_hash.to_json(*args)
			end

			attr_writer :parent_resource
		end
	end
end

