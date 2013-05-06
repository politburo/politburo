module Politburo
	module Resource
		class Environment < Base
			requires :parent_resource

      attr_accessor :key_pair

      attr_with_default(:private_keys_path) { root.cli.private_keys_path }
		end

	end
end

