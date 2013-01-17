require 'fog'
require 'fog/compute/models/server'

module Politburo
  module Plugins
    module Cloud
      class Provider
        attr_reader :config

        def initialize(config)
          @config = config
        end

        def compute_instance
          @compute_instance ||= begin 
            compute = Fog::Compute.new(config)

            Fog::Compute::Server.class_eval do
              include Politburo::Plugins::Cloud::Server
            end

            Fog::SSH::Real.class_eval do
              include Politburo::Plugins::Cloud::FogSSHExtensions
            end
            
            Fog::Compute::AWS::SecurityGroup.class_eval do
              include Politburo::Plugins::Cloud::FogSecurityGroupExtensions
            end if (config[:provider] == "AWS")
            
            compute
          end
        end

        def find_or_create_server_for(node)
          find_server_for(node) || create_server_for(node)
        end

        def flavor_for(node)
          node[:flavor] || default_flavor
        end

        def image_for(node)
          node[:image] || default_image
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
