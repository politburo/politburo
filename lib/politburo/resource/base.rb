module Politburo
	module Resource
		class Base
			attr_reader :parent_resource

			def initialize(parent_resource = nil)
				@parent_resource = parent_resource
			end
		end
	end
end

