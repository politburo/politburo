module Politburo
  module Plugins
    module Cloud
      module CloudResource
        include Politburo::DSL::DslDefined

        inherits :provider
        inherits :provider_config
        inherits :region

        requires :provider
        requires :region

        attr_with_default(:cloud_counterpart_name) { default_cloud_counterpart_name }

        def default_cloud_counterpart_name
          full_name
        end

        def destroy_cloud_counterpart
          cloud_counterpart.destroy
        end

        def self.included(base)
          base.extend(ClassMethods)
        end

        module ClassMethods
        end

      end
    end
  end
end
