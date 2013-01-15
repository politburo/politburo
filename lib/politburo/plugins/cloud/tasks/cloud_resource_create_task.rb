module Politburo
  module Plugins
    module Cloud
      module Tasks
        class CloudResourceCreateTask < Politburo::Resource::StateTask

          attr_accessor :noun
          attr_accessor :create_using

          def met?(verification = false)
            logger.info("Searching for existing #{noun}...") unless verification
            cloud_counterpart = resource.cloud_counterpart
            logger.info("Identified existing #{noun}: #{cloud_counterpart.display_name.cyan}") if (cloud_counterpart) and (!verification)
            cloud_counterpart
          end

          def verify_met?
            met?(true)
          end

          def meet
            cloud_counterpart = create_using.call(resource)
            logger.info("Created new #{noun}: #{cloud_counterpart.display_name.cyan}") if (cloud_counterpart)
            cloud_counterpart        
          end
        end
      end
    end
  end
end