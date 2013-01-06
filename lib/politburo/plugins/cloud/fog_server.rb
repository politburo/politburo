# Monkey patch to provide a display name to servers irrespectively of provider
module Politburo
  module Plugins
    module Cloud
      module Server

        def display_name
          return self.dns_name if self.respond_to?(:dns_name) and self.dns_name
          return self.id
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
