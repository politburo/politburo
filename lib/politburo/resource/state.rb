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

			def inspect
				"#<#{self.class.name} \"#{full_name}\">"
			end

			def parent_resource=(resource)
				self.resource= resource
			end

			def parent_resource()
				self.resource
			end

			def context
				@context ||= StateContext.new(self)
			end

			def release
				# To be overriden by subclasses
			end

			def to_task
				@task ||= Politburo::Resource::StateTask.new(self)
			end

			def as_dependency
				self
			end

			def full_name()
				"#{resource.full_name}##{name}"
			end

			def to_json_hash()
				{
						name: name,
						dependencies: dependencies.map(&:full_name),
				}
			end

			def to_json(*args) 
				to_json_hash.to_json(*args)
			end

			attr_writer :resource

		end

		class StateContext < Politburo::DSL::Context

			def requires(task)
				puts "Requires: #{task.to_s}"
			end

		end
	end
end

