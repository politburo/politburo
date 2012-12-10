require 'fog'

module Politburo
  module Resource
    module Cloud
      class Providers

        def self.provider_types
          {
            aws: Politburo::Resource::Cloud::AWSProvider
          }
        end

        def self.for(resource)
          provider_types[resource.provider].for(resource)
        end

        private
        
        def initialize()
          raise "Static singleton!"
        end

      end
    end
  end
end
