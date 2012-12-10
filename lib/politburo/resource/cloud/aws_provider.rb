module Politburo
  module Resource
    module Cloud
      class AWSProvider < Provider

        def self.config_for(resource)
          { provider: 'AWS' }.merge(resource.provider_config).merge(region: resource.availability_zone )
        end

      end
    end
  end
end
