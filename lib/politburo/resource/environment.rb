module Politburo
	module Resource
		class Environment < Base
      attr_accessor :flavor
			attr_accessor :availability_zone

			requires :flavor
			requires :parent_resource

		end
	end
end

