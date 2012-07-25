module Politburo
	module Resource
		class Environment < Base
			attr_accessor :environment_flavour

			requires :environment_flavour

			def initialize(parent_resource)
				super(parent_resource)
			end


		end
	end
end

