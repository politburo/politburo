module Politburo
  module Plugins
    module Cloud
      class Facet < Politburo::Resource::Facet

        inherits :provider
        inherits :provider_config
        inherits :region

        requires :provider

      end
    end
  end
end