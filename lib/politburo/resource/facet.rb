module Politburo
  module Resource
    class Facet < Base
      inherits :provider
      inherits :availability_zone

      requires :provider
      requires :parent_resource

      def initialize(parent_resource)
        super(parent_resource)
      end

    end
  end
end

