module Politburo
  module Resource
    module Cloud
      class AWSProvider < Provider

        def self.config_for(resource)
          { provider: 'AWS' }.merge(resource.provider_config).merge(region: resource.availability_zone )
        end

        def find_server_for(node)
          matching_servers = compute_instance.servers.select do | s | 
            not s.tags.select { | k,v | k == "politburo:full_name" and v == node.full_name }.empty?
          end          

          return nil if matching_servers.empty?
          raise "More than one cloud server tagged with the full name: '#{node.full_name}'. Matching servers: #{matching_servers.inspect}" unless matching_servers.length == 1
          matching_servers.first
        end

        def create_server_for(node)
          server = compute_instance.servers.create(flavor_id: 1, image_id: 3, name: "#{node.name}", tags: { "politburo:full_name" => node.full_name })
          server.wait_for { server.ready? }
        end

      end
    end
  end
end
