module Politburo
  module Plugins
    module Cloud
      module RootContextExtensions

        def self.load(context) 
          context.noun(:environment)  { | context, attributes, &block | context.lookup_or_create_resource(::Politburo::Plugins::Cloud::Environment, attributes, &block) }
        end

      end

    end
  end
end

