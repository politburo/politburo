module Politburo
	module Resource
		class Environment < Base
      attr_accessor :flavour
			attr_accessor :availability_zone

			requires :flavour
			requires :parent_resource

		end
	end
end

