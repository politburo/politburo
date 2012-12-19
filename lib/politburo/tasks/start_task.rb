module Politburo
  module Tasks
    class StartTask < Politburo::Resource::StateTask

      def met?
        server = resource.cloud_server
        server and server.ready?
      end

      def meet
        server = resource.cloud_server
        if (server.state == "stopping")
          logger.info("Server #{server.display_name.cyan} is still stopping, will wait for it to fully stop before attempting to start it up again...")
          server.wait_for { state != "stopping" }
        end

        if (server.state == "stopped")
          logger.info("Server #{server.display_name.cyan} was stopped, requesting start now...")
          server.start 
        end

        logger.info("Waiting for server #{server.display_name.cyan} to become available...")
        result = server.wait_for { ready? }

        logger.info("Server is now available. Took #{result[:duration]} second(s).")
        true
      end
    end
  end
end
