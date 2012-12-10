require 'fog'

module Politburo
  module Resource
    module Cloud
      class Provider
        attr_reader :config

        def initialize(config)
          @config = config
        end

        def compute_instance
          @compute_instance ||= Fog::Compute.new(config)
        end

        def self.mutex
          @mutex ||= Mutex.new
        end

        def self.for(resource)
          config = config_for(resource)

          mutex.synchronize do
            @providers ||= {}
            @providers[config] ||= self.new(config)
          end
        end

      end
    end
  end
end
