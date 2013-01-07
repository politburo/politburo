module Politburo
  module Plugins
    module Cloud
      class Plugin < Politburo::Plugins::Plugin

        def apply
          logger.debug("Applying Cloud Plug-in...")
        end

      end

      Politburo::DSL.default_plugins << Politburo::Plugins::Cloud::Plugin
    end
  end
end

