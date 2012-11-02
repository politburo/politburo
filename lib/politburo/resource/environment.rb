module Politburo
	module Resource
		class Environment < Base
			attr_accessor :flavour

			requires :flavour
			requires :parent_resource

		end
	end
end

