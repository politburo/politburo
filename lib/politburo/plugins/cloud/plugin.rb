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
          node.context.define {
            state(:created)     { create_and_define_resource(Politburo::Plugins::Cloud::Tasks::CreateTask,    name: "Create server")    {} }
            state(:starting)    { create_and_define_resource(Politburo::Plugins::Cloud::Tasks::StartTask,     name: "Start server")     {} }
            state(:stopped)     { create_and_define_resource(Politburo::Plugins::Cloud::Tasks::StopTask,      name: "Stop server")      {} }
            state(:terminated)  { create_and_define_resource(Politburo::Plugins::Cloud::Tasks::TerminateTask, name: "Terminate server") {} }

            parent {
              security_group(name: "Default Security Group", region: node.region) { }              
            }

            self.default_security_group = security_group(name: "Default Security Group", region: node.region).receiver
            depends_on security_group(name: "Default Security Group", region: node.region)
          }

        end

      end

      Politburo::DSL.default_plugins << Politburo::Plugins::Cloud::Plugin
    end
  end
end

