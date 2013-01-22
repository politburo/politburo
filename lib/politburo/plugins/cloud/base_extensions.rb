module Politburo
  module Plugins
    module Cloud
      module BaseExtensions

        def cloud_provider
          Politburo::Plugins::Cloud::Providers.for(self)
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

