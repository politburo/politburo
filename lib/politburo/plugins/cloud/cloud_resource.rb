module Politburo
  module Plugins
    module Cloud
      class CloudResource < Politburo::Resource::Base
        inherits :provider
        inherits :provider_config
        inherits :region

        requires :provider
        requires :region

        attr_with_default(:cloud_counterpart_name) { default_cloud_counterpart_name }

        def default_cloud_counterpart_name
          full_name
        end

      end
    end
  end
end
