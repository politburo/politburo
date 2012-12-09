module Politburo
  module Resource
    module Cloud
      class Provider

        @mutex = Mutex.new

        def self.provider_types
          {
            aws: Politburo::Resource::Cloud::AWSProvider.class
          }
        end

        def self.for(provider_type, provider_config)
          @mutex.synchronize do
            @providers ||= {}
            @providers[{ type: provider_type, config: provider_config }] ||= provider_types[provider_type].new(provider_config)
          end
        end

      end
    end
  end
end
