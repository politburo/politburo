module Politburo
  module Plugins
    module Cloud
      class KeyPair < Politburo::Resource::KeyPair
        include CloudResource

        implies {
          state(:created)     { create_and_define_resource(Politburo::Plugins::Cloud::Tasks::KeyPairCreateTask,           name: "Create key pair") {} } 
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
