module Politburo
  module Tasks
    class CreateTask < Politburo::Resource::StateTask

      def met?
        logger.info("Searching for existing server for node...")
        server = resource.cloud_server
        logger.info("\tIdentified existing server: #{server.display_name.cyan}") if (server)
        server
      end

      def meet
        server = resource.cloud_provider.find_or_create_server_for(resource)
        logger.info("\tCreated new server: #{server.display_name.cyan}") if (server)
        server        
      end
    end
  end
end
