module Politburo
  module Plugins
    module Babushka
      class Plugin < Politburo::Plugins::Base

        def load(context)
          context.noun(:babushka_task)  { | context, attributes, &block | context.lookup_or_create_resource(::Politburo::Plugins::Babushka::BabushkaTask, attributes, &block) }
        end

        def apply
        end

      end

    end
  end
end

