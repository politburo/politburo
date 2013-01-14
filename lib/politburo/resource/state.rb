module Politburo
	module Resource
		class State
			include ::Politburo::DSL::DslDefined
			include ::Politburo::Resource::HasHierarchy
			include ::Politburo::Resource::Searchable
			include ::Politburo::Resource::HasDependencies

			attr_accessor :name

			requires :parent_resource
			requires :name

			def initialize(attributes)
				update_attributes(attributes)
			end

			def context_class
				StateContext
			end

			def tasks
				children
			end

			def inspect
				"<#{self.class.to_s}:#{"0x%x" % self.__id__} \"#{full_name}\">"
			end

			def to_s
				"<#{self.class.to_s}:#{"0x%x" % self.__id__} \"#{full_name}\">"
			end

			def state_dependencies
				dependencies.select { | dep | dep.is_a?(State) }
			end

			def release
				# To be overriden by subclasses
			end

			def to_task
				@task ||= begin
					state_task = Politburo::Resource::StateTask.new(dependencies: self.dependencies)

					add_child(state_task)

					state_task
				end
			end

			def as_dependency
				self
			end

			def full_name()
				"#{parent_resource.full_name}##{name}"
			end

		end

	end
end

