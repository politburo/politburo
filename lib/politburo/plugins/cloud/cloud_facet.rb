module Politburo
  module Plugins
    module Cloud
      class Facet < Politburo::Resource::Facet
        include CloudCommon
      end
    end
  end
end