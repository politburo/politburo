module Politburo
  module Tasks
    class StopTask < Politburo::Resource::StateTask

      def met?
        server = resource.cloud_server
        if server.nil?
          resource.logger.info("No server, so nothing to stop.")
          return true
        elsif  %w(stopped stopping).include?(server.state)
          resource.logger.info("Server #{server.id.cyan} already #{server.state}.")
          return true
        end

        return false
      end

      def meet
        server = resource.cloud_server
        
        resource.logger.info("Stopping server: #{server.dns_name.nil? ? server.id.cyan : server.dns_name.cyan}")
        server.stop
        server.wait_for { state == "stopped" }
      end
    end
  end
end
