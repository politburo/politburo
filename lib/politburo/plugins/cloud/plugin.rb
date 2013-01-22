module Politburo
  module Plugins
    module Cloud
      class Plugin < Politburo::Plugins::Base

        def load(context)
          Politburo::Resource::Base.class_eval { include Politburo::Plugins::Cloud::BaseExtensions }
          Politburo::Plugins::Cloud::RootContextExtensions.load(context)
          Politburo::Plugins::Cloud::EnvironmentContextExtensions.load(context)
        end

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

            state(:created).depends_on security_group(name: "Default Security Group", region: node.region).state(:created)
            security_group(name: "Default Security Group", region: node.region).state(:terminated).depends_on state(:terminated)

            lookup(class: lambda { |obj, attr, value| obj.is_a? Politburo::Plugins::Cloud::Environment } ) {
              key_pair(name: "Default Key Pair for #{node.region}", region: node.region) { }
            }

            kp = receiver.key_pair.context
            state(:created).depends_on kp
            kp.state(:terminated).depends_on state(:terminated)
          }

        end

      end

    end
  end
end

