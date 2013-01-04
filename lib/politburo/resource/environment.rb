module Politburo
	module Resource
		class Environment < Base
      attr_accessor :provider
      attr_accessor :provider_config
			attr_accessor :region

			requires :provider
			requires :parent_resource

      def context_class
        EnvironmentContext
      end

		end

    class EnvironmentContext < Politburo::Resource::RootContext

      def node(attributes, &block)
        find_or_create_resource(::Politburo::Resource::Node, attributes, &block)
      end

      def facet(attributes, &block)
        find_or_create_resource(::Politburo::Resource::Facet, attributes, &block)
      end

      def state(attributes, &block)
        lookup_and_define_resource(::Politburo::Resource::State, attributes, &block)
      end

      def remote_task(attributes, &block)
        find_or_create_resource(::Politburo::Tasks::RemoteTask, attributes, &block)
      end
      
    end


	end
end

