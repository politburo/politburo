module Politburo
  module Tasks
    class TerminateTask < Politburo::Resource::StateTask

      def met?
        server = resource.cloud_server
        if server.nil?
          logger.info("No server, so nothing to terminate.")
          return true
        elsif  %w(terminated).include?(server.state)
          logger.info("Server #{server.display_name.cyan} is #{server.state}.")
          return true
        end

        return false
      end

      def meet
        server = resource.cloud_server
        
        if (server.state != "terminated")
          logger.info("Terminating server: #{server.display_name.cyan}...")
          server.destroy
        end

        logger.info("Waiting for server #{server.display_name.cyan} to terminate...")
        server.wait_for { state == "terminated" }
      end
    end
  end
end
