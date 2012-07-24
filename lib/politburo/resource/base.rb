module Politburo
	module Resource
		class Base
			include Politburo::DSL::DslDefined

			attr_reader :parent_resource
			attr_accessor :name

			requires :name

			def initialize(parent_resource = nil)
				@parent_resource = parent_resource
			end


		end
	end
end

