module Politburo
  module Resource
    class Facet < Base
      requires :parent_resource

      def context_class
        FacetContext
      end

    end

    class FacetContext < Politburo::Resource::EnvironmentContext
    end

  end
end

