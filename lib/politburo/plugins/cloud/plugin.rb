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
          node.state(:created).context.define    { create_and_define_resource(Politburo::Plugins::Cloud::Tasks::CreateTask,    name: "Create server")    {} }
          node.state(:starting).context.define   { create_and_define_resource(Politburo::Plugins::Cloud::Tasks::StartTask,     name: "Start server")     {} }
          node.state(:stopped).context.define    { create_and_define_resource(Politburo::Plugins::Cloud::Tasks::StopTask,      name: "Stop server")      {} }
          node.state(:terminated).context.define { create_and_define_resource(Politburo::Plugins::Cloud::Tasks::TerminateTask, name: "Terminate server") {} }

          raise "Node without parent" if node.parent_resource.nil?

          node.parent_resource.context.define do
            security_group(name: "Default Security Group", region: node.region) { }
          end

        end

      end

      Politburo::DSL.default_plugins << Politburo::Plugins::Cloud::Plugin
    end
  end
end

