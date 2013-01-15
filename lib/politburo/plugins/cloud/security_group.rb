module Politburo
  module Plugins
    module Cloud
      class SecurityGroup < Politburo::Resource::Base
        inherits :provider
        inherits :provider_config
        inherits :region

        requires :provider

        implies {
          state(:created)     { create_and_define_resource(Politburo::Plugins::Cloud::Tasks::SecurityGroupCreateTask,     name: "Create security group") {} } 
          state(:terminated)  { create_and_define_resource(Politburo::Plugins::Cloud::Tasks::SecurityGroupTerminateTask,  name: "Delete security group") {} } 
        }

        def cloud_security_group
          cloud_provider.find_security_group_for(self)
        end

      end
    end
  end
end
