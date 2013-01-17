module Politburo
	module Resource
		class Environment < Base
			requires :parent_resource

      def context_class
        EnvironmentContext
      end

		end

    class EnvironmentContext < Politburo::Resource::RootContext

      def node(attributes, &block)
        lookup_or_create_resource(::Politburo::Resource::Node, attributes, &block)
      end

      def facet(attributes, &block)
        lookup_or_create_resource(::Politburo::Resource::Facet, attributes, &block)
      end

    end

	end
end

