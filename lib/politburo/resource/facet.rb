module Politburo
  module Resource
    class Facet < Base
      inherits :provider
      inherits :provider_config
      inherits :region

      requires :provider
      requires :parent_resource

      def initialize(parent_resource)
        super(parent_resource)
      end

      def context_class
        FacetContext
      end

    end

    class FacetContext < Politburo::Resource::EnvironmentContext
    end

  end
end

