module Politburo
  module Plugins
    module Cloud
      class SecurityGroup < Politburo::Resource::Base
        inherits :provider
        inherits :provider_config
        inherits :region

        requires :provider
      end
    end
  end
end
