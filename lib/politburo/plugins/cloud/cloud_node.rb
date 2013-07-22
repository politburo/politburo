module Politburo
  module Plugins
    module Cloud
      class Node < Politburo::Resource::Node
        include CloudCommon

        attr_with_default(:host) { cloud_server.dns_name }

        attr_accessor :flavor

        attr_accessor :default_security_group

        def cloud_server
          if @cloud_server.nil? 
            @cloud_server = cloud_provider.find_server_for(self)
          else
            @cloud_server = @cloud_server.reload
          end

          @cloud_server.private_key =  key_pair.private_key_content unless @cloud_server.nil?

          @cloud_server
        end
        
        def create_session
          cloud_server.create_ssh_session
        end
      end
    end
  end
end
