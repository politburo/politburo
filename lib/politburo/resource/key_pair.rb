module Politburo
  module Resource
    class KeyPair < Politburo::Resource::Base
      inherits :private_keys_path

      attr_with_default(:private_key_file_name) { "#{cloud_counterpart_name.gsub(/\W/, '_')}.pem" }
      attr_with_default(:private_key_path) { private_keys_path + private_key_file_name }
      attr_with_default(:private_key_content ) { private_key_path.read }

      attr_with_default(:public_key_file_name) { "#{cloud_counterpart_name.gsub(/\W/, '_')}.pub" }
      attr_with_default(:public_key_path) { private_keys_path + public_key_file_name }
     
    end
  end
end
