module Politburo
  module Resource
    class Root < Base

      attr_accessor :cli

      requires :cli

      def parent_resource
        nil
      end

      def apply_plugins
        find_all_by_attributes(class: lambda { | obj, attr_name, value | obj.respond_to?(:apply) } ).map(&:apply)
      end

      def context
        receiver = self
        @context ||= begin
          context = Politburo::DSL::Context.new(self)

          context.noun(:environment)  { | context, attributes, &block | context.lookup_or_create_resource(::Politburo::Resource::Environment, attributes, &block) }
          context.noun(:node)         { | context, attributes, &block | context.lookup_or_create_resource(::Politburo::Resource::Node, attributes, &block) }
          context.noun(:facet)        { | context, attributes, &block | context.lookup_or_create_resource(::Politburo::Resource::Facet, attributes, &block) }
          context.noun(:group)        { | context, attributes, &block | context.lookup_or_create_resource(::Politburo::Resource::Facet, attributes, &block) }
          context.noun(:remote_task)  { | context, attributes, &block | context.lookup_or_create_resource(::Politburo::Tasks::RemoteTask, attributes, &block) }

          context.noun(:plugin) { | context, attributes, &block | 
            klass = attributes.delete(:class)
            attributes[:name] ||= klass.to_s
            plugin_context = context.lookup_or_create_resource(klass, attributes, &block)
            plugin_context.receiver.load(context)
            plugin_context
          }

          context
        end
      end

    end

  end
end

