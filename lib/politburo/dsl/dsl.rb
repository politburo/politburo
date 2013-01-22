module Politburo
  module DSL

    def self.define(definition = nil, plugins = [], &block)
      root_resource = Politburo::Resource::Root.new(name: "")
      root_context = root_resource.context

      plugins.each do | plugin_class |
        root_context.plugin(class: plugin_class) {}
      end

      root_context.evaluate_implied
      root_context.define(definition, &block)

      root_resource.apply_plugins
      root_context.send(:validate!)

      root_resource
    end

  end
end
