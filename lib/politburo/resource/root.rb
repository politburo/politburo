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

          context.add_noun_and_type(:environment, ::Politburo::Resource::Environment)
          context.add_noun_and_type(:node,::Politburo::Resource::Node)
          context.add_noun_and_type(:facet, ::Politburo::Resource::Facet)
          context.add_noun_and_type(:group, ::Politburo::Resource::Facet)
          context.add_noun_and_type(:remote_task, ::Politburo::Tasks::RemoteTask)

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

