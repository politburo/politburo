module Politburo
  module Plugins
    module Cloud
      class Plugin < Politburo::Plugins::Base

        def apply
          logger.debug("Applying Cloud Plug-in...")

          root.select { | obj | obj.kind_of?(Politburo::Resource::Node) }.each do | node | 
            apply_to_node(node)
          end
        end

        def apply_to_node(node)
          node.context.define do
            state(name: :created,    parent_resource: receiver) { create_and_define_resource(Politburo::Tasks::CreateTask,    name: "Create server")    {} }
            state(name: :starting,   parent_resource: receiver) { create_and_define_resource(Politburo::Tasks::StartTask,     name: "Start server")     {} }
            state(name: :stopped,    parent_resource: receiver) { create_and_define_resource(Politburo::Tasks::StopTask,      name: "Stop server")      {} }
            state(name: :terminated, parent_resource: receiver) { create_and_define_resource(Politburo::Tasks::TerminateTask, name: "Terminate server") {} }
          end

          raise "Node without parent" if node.parent_resource.nil?

          node.parent_resource.context.define do
            if find_all_by_attributes({ class: Politburo::Plugins::Cloud::SecurityGroup, name: "Default Security Group", region: node.region }).empty?
              security_group(name: "Default Security Group", region: node.region) { }
            end              
          end

        end

      end

      Politburo::DSL.default_plugins << Politburo::Plugins::Cloud::Plugin
    end
  end
end

