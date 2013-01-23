module Politburo
  module Plugins
    module Cloud
      module Tasks
        class StartTask < Politburo::Resource::StateTask

          def met?(verification = false)
            server = resource.cloud_server
            return false unless server

            ready = verification ? server.wait_for { ready? } : server.ready?
            logger.error("Server #{server.display_name.cyan} is still not ready.") if !ready and verification
            return false unless ready

            sshable = verification ? server.wait_for { sshable? } : server.sshable?
            logger.error("Server #{server.display_name.cyan} is still not sshable.") if !sshable and verification
            return false unless sshable
            
            server and ready and sshable
          end

          def meet(try = 0)
            server = resource.cloud_server

            logger.warn("Trying again, retry #{try}...") if (try > 0)

            if (server.state == "stopping")
              logger.info("Server #{server.display_name.cyan} is still stopping, will wait for it to fully stop before attempting to start it up again...")
              unless server.wait_for(180) { state != "stopping" }
                logger.error("Timed out while waiting for server #{server.display_name.cyan} to fully stop.")
                raise "Timed out while waiting for server #{server.display_name} to fully stop."
              end
            end

            if (server.state == "stopped")
              logger.info("Server #{server.display_name.cyan} was stopped, requesting start now...")
              server.start 
            else
              logger.info("Waiting for server #{server.display_name.cyan} to become available...")
            end

            ready_result = resource.cloud_server.wait_for(180) { ready? }
            if (ready_result)
              logger.info("Server #{server.reload.display_name.cyan} is now ready. Took #{ready_result[:duration]} second(s).")
            else
              logger.error("Timed out while waiting for server #{server.display_name.cyan} to become available.")
              raise "Timed out while waiting for server #{server.display_name} to become available."
            end

            logger.info("Waiting for server #{server.display_name.cyan} to become sshable...")
            sshable_result = resource.cloud_server.wait_for(180) { sshable? }

            if sshable_result
              logger.info("Server #{server.reload.display_name.cyan} is now sshable. Took #{sshable_result[:duration]} second(s).")
            else
              logger.error("Timed out while waiting for ssh access to server #{server.display_name.cyan}.")
              raise "Timed out while waiting for ssh access to server #{server.display_name}."
            end

            true
          end
        end
      end
    end
  end
end