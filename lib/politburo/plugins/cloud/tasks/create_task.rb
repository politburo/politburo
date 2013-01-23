module Politburo
  module Plugins
    module Cloud
      module Tasks
        class CreateTask < Politburo::Resource::StateTask

          def met?(verification = false)
            logger.info("Searching for existing server for node...") unless verification
            server = resource.cloud_server
            logger.info("Identified existing server: #{server.display_name.cyan}") if (server) and (!verification)
            server
          end

          def meet(try = 0)
            server = resource.cloud_provider.find_or_create_server_for(resource)
            logger.info("Created new server: #{server.display_name.cyan}") if (server)
            server        
          end
        end
      end
    end
  end
end