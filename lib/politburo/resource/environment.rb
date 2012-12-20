module Politburo
	module Resource
		class Environment < Base
      attr_accessor :provider
      attr_accessor :provider_config
			attr_accessor :region

			requires :provider
			requires :parent_resource

		end
	end
end

