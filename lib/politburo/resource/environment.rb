module Politburo
	module Resource
		class Environment < Base
			attr_accessor :environment_flavour

			requires :environment_flavour
			requires :parent_resource

		end
	end
end

