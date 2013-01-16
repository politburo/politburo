module Politburo
  module Plugins
    module Cloud
      class KeyPair < CloudResource
        inherits :private_keys_path

        attr_with_default(:private_key_file_name) { "#{cloud_counterpart_name.gsub(/\W/, '_')}.pem" }
        attr_with_default(:private_key_path) { private_keys_path + private_key_file_name }

        attr_with_default(:public_key_file_name) { "#{cloud_counterpart_name.gsub(/\W/, '_')}.pub" }
        attr_with_default(:public_key_path) { private_keys_path + public_key_file_name }

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
