module Politburo
	module Resource
		class State
			include ::Politburo::DSL::DslDefined
			include ::Politburo::Resource::Searchable
			include ::Politburo::Resource::HasDependencies

			attr_reader :resource
			attr_accessor :name

			requires :resource
			requires :name

			def initialize(attributes)
				update_attributes(attributes)
				resource.states << self
			end

			def parent_resource=(resource)
				self.resource= resource
			end

			def parent_resource()
				self.resource
			end

			def context_class
				StateContext
			end

			def contained_searchables
				dependencies
			end			

			def tasks
				@tasks ||= Set.new
			end

			def state_dependencies
				dependencies.select { | dep | dep.is_a?(State) }
			end

			def release
				# To be overriden by subclasses
			end

			def to_task
				@task ||= Politburo::Resource::StateTask.new(parent_resource: self, dependencies: self.dependencies)
			end

			def as_dependency
				self
			end

			def full_name()
				"#{resource.full_name}##{name}"
			end

			attr_writer :resource

		end

	end
end

