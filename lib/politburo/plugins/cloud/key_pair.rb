module Politburo
  module Plugins
    module Cloud
      class KeyPair < CloudResource
        implies {
          state(:created)     { create_and_define_resource(Politburo::Plugins::Cloud::Tasks::CloudResourceCreateTask,     name: "Create key pair", noun: 'key pair', create_using: lambda { | kp | raise "Not yet implemented." }) {} } 
          state(:terminated)  { create_and_define_resource(Politburo::Plugins::Cloud::Tasks::CloudResourceTerminateTask,  name: "Delete key pair", noun: 'key pair') {} } 
        }

        def default_cloud_counterpart_name
          parent_resource.name
        end

        def cloud_key_pair
          cloud_provider.find_key_pair_for(self)
        end

        def cloud_counterpart
          cloud_key_pair
        end
        
      end
    end
  end
end
