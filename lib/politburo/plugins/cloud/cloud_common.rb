module Politburo
  module Plugins
    module Cloud
      module CloudCommon
        include Politburo::DSL::DslDefined

        inherits :provider
        inherits :provider_config
        inherits :region

        requires :provider
        requires :region

        attr_with_default(:key_pair) { (parent_resource.nil? ? nil : parent_resource.key_pair) || self.context.lookup(name: "Default Key Pair for #{self.region}", class: Politburo::Plugins::Cloud::KeyPair, region: self.region).receiver }

        def self.included(base)
          base.extend(ClassMethods)
        end

        module ClassMethods
        end

      end
    end
  end
end
