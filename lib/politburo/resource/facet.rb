module Politburo
  module Resource
    class Facet < Base
      inherits :flavour
      inherits :availability_zone

      requires :flavour
      requires :parent_resource

      def initialize(parent_resource)
        super(parent_resource)
      end

    end
  end
end

