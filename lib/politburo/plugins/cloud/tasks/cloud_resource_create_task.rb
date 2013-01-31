module Politburo
  module Plugins
    module Cloud
      module Tasks
        class CloudResourceCreateTask < Politburo::Resource::StateTask

          attr_accessor :noun

          def met?(verification = false)
            logger.info("Searching for existing #{noun}...") unless verification
            cloud_counterpart = resource.cloud_counterpart
            logger.info("Identified existing #{noun}: #{cloud_counterpart.display_name.cyan}") if (cloud_counterpart) and (!verification)
            cloud_counterpart
          end

          def meet(try = 0)
            cloud_counterpart = resource.create_cloud_counterpart
            logger.info("Created new #{noun}: #{cloud_counterpart.display_name.cyan}") if (cloud_counterpart)
            cloud_counterpart        
          end
        end
      end
    end
  end
end