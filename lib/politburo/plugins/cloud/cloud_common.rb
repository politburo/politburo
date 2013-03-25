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

        def self.included(base)
          base.extend(ClassMethods)
        end

        module ClassMethods
        end

      end
    end
  end
end
