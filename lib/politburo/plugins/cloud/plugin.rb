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
          node.state(:created).add_dependency_on(Politburo::Tasks::CreateTask.new(name: "Create server", resource_state: node.state(:created)))
          node.state(:starting).add_dependency_on(Politburo::Tasks::StartTask.new(name: "Start server", resource_state: node.state(:starting)))
          node.state(:stopped).add_dependency_on(Politburo::Tasks::StopTask.new(name: "Stop server", resource_state: node.state(:stopped)))
          node.state(:terminated).add_dependency_on(Politburo::Tasks::TerminateTask.new(name: "Terminate server", resource_state: node.state(:terminated)))
        end
        
      end

      Politburo::DSL.default_plugins << Politburo::Plugins::Cloud::Plugin
    end
  end
end

