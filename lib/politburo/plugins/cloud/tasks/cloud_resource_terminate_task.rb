module Politburo
  module Plugins
    module Cloud
      module Tasks
        class CloudResourceTerminateTask < Politburo::Resource::StateTask

          attr_accessor :noun

          def met?(verification = false)
            cloud_resource = resource.cloud_counterpart
            if cloud_resource.nil?
              logger.info("No #{noun}, so nothing to delete.") unless verification
              return true
            end

            return false
          end

          def meet(try = 0)
            cloud_resource = resource.cloud_counterpart
            logger.info("Deleting #{noun}: #{cloud_resource.display_name.cyan}...")
            resource.destroy_cloud_counterpart

            true
          end
        end
      end
    end
  end
end
