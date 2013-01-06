module Politburo
  module Plugins
    module Cloud
      class Plugin < Politburo::Plugins::Plugin
      end

      Politburo::DSL.default_plugins << Politburo::Plugins::Cloud::Plugin
    end
  end
end
