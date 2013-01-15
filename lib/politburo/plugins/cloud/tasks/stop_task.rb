module Politburo
  module Plugins
    module Cloud
      module Tasks
        class StopTask < Politburo::Resource::StateTask

          def met?(verification = false)
            server = resource.cloud_server
            if server.nil?
              logger.info("No server, so nothing to stop.")
              return true
            elsif  %w(stopped).include?(server.state)
              logger.info("Server #{server.display_name.cyan} is #{server.state}.")
              return true
            end

            return false
          end

          def meet
            server = resource.cloud_server
            
            if (server.state != "stopped")
              logger.info("Stopping server: #{server.display_name.cyan}...")
              server.stop
            end

            server.wait_for { state == "stopped" }
          end
        end
      end
    end
  end
end
