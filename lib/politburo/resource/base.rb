module Politburo
	module Resource
		class Base
			include Politburo::DSL::DslDefined
			include Politburo::Resource::Searchable

			attr_reader :parent_resource

			attr_accessor :name

			requires :name

			def initialize(parent_resource = nil)
				@parent_resource = parent_resource
				@parent_resource.children << self unless @parent_resource.nil?
			end

			def children()
				@children ||= []
			end

			def root()
				parent_resource.nil? ? self : parent_resource.root
			end
		end
	end
end

