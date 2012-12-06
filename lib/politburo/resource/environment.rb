module Politburo
	module Resource
		class Environment < Base
      attr_accessor :provider
			attr_accessor :availability_zone

			requires :provider
			requires :parent_resource

		end
	end
end

