module Politburo
	module Resource
		class Base
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

			def contained_searchables
				Set.new().merge(children).merge(states)
			end

			def add_dependency_on(target)
				state(:ready).add_dependency_on(target)
			end

			def generate_babushka_deps(io)
				states.each { | s | s.generate_babushka_deps(io) }

				io
			end

			attr_writer :parent_resource
		end
	end
end

