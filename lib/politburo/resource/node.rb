module Politburo
	module Resource
		class Node < Base
			attr_accessor :node_flavour

			requires :node_flavour

			def initialize(parent_resource)
				super(parent_resource)
			end

		end
	end
end

