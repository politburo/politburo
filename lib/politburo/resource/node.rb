module Politburo
	module Resource
		class Node < Base
			attr_accessor :node_flavour
			attr_accessor :host

			requires :node_flavour
			requires :parent_resource

			def initialize(parent_resource)
				super(parent_resource)
			end

		end
	end
end

