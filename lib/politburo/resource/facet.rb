module Politburo
  module Resource
    class Facet < Base
      inherits :flavor
      inherits :availability_zone

      requires :flavor
      requires :parent_resource

      def initialize(parent_resource)
        super(parent_resource)
      end

    end
  end
end

