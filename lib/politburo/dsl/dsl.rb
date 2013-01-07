module Politburo
  module DSL
    def self.default_plugins
      @default_plugins ||= Set.new
    end

    def self.define(definition = nil, &block)
      root_resource = Politburo::Resource::Root.new(name: "")
      root_context = root_resource.context
      root_context.define(definition, &block)

      default_plugins.each do | plugin_class |
        root_context.plugin(class: plugin_class) {}
      end

      root_resource.apply_plugins
      root_context.send(:validate!)

      root_resource
    end

  end
end
