module Politburo
  module Plugins
    module Cloud
      class Environment < Politburo::Resource::Environment
        attr_accessor :provider
        attr_accessor :provider_config
        attr_accessor :region

        requires :provider
      end

      module EnvironmentContextExtensions

        def self.load(context)
          context.add_noun_and_type(:node, ::Politburo::Plugins::Cloud::Node)
          context.add_noun_and_type(:facet, ::Politburo::Plugins::Cloud::Facet)
          context.add_noun_and_type(:group, ::Politburo::Plugins::Cloud::Facet)
          context.add_noun_and_type(:security_group, ::Politburo::Plugins::Cloud::SecurityGroup)
          context.add_noun_and_type(:key_pair, ::Politburo::Plugins::Cloud::KeyPair)
        end

      end

    end
  end
end

