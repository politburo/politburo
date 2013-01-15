module Politburo
  module Plugins
    module Cloud
      module FogSecurityGroupExtensions

        def display_name
          self.group_id
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
