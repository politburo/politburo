module Politburo
  module DSL
    def self.default_plugins
      @default_plugins ||= Set.new
    end

    def self.define(definition = nil, &block)
      root_resource = Politburo::Resource::Root.new(name: "")
      root_context = root_resource.context
      root_context.define(definition, &block)
      root_resource.apply_plugins
      root_context.send(:validate!)

      root_resource
    end

  end
end
