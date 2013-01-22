module Politburo
  module Plugins
    module Cloud
      class Environment < Politburo::Resource::Environment
        attr_accessor :provider
        attr_accessor :provider_config
        attr_accessor :region

        requires :provider
        
        attr_with_default(:private_keys_path) { root.cli.private_keys_path }

      end

      module EnvironmentContextExtensions

        def self.load(context)
          context.noun(:node)           { | context, attributes, &block | context.lookup_or_create_resource(::Politburo::Plugins::Cloud::Node, attributes, &block) }
          context.noun(:facet)          { | context, attributes, &block | context.lookup_or_create_resource(::Politburo::Plugins::Cloud::Facet, attributes, &block) }
          context.noun(:group)          { | context, attributes, &block | context.lookup_or_create_resource(::Politburo::Plugins::Cloud::Facet, attributes, &block) }
          context.noun(:security_group) { | context, attributes, &block | context.lookup_or_create_resource(::Politburo::Plugins::Cloud::SecurityGroup, attributes, &block) }
          context.noun(:key_pair)       { | context, attributes, &block | context.lookup_or_create_resource(::Politburo::Plugins::Cloud::KeyPair, attributes, &block) }
        end

      end

    end
  end
end

