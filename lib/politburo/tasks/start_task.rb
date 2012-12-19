module Politburo
  module Tasks
    class StartTask < Politburo::Resource::StateTask

      def met?
        server = resource.cloud_server
        server and server.ready?
      end

      def meet
        if (resource.cloud_server.state == "stopping")
          resource.logger.info("Server is still stopping, will wait for it to fully stop before attempting to start it up again...")
          resource.cloud_server.wait_for { state != "stopping" }
        end

        if (resource.cloud_server.state == "stopped")
          resource.logger.info("Server was stopped, requesting start now...")
          resource.cloud_server.start 
        end

        resource.logger.info("Waiting for server to become available...")
        result = resource.cloud_server.wait_for { ready? }

        resource.logger.info("Server is now available. Took #{result[:duration]} second(s).")
        true
      end
    end
  end
end
