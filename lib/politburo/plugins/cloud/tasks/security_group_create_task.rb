module Politburo
  module Plugins
    module Cloud
      module Tasks
        class SecurityGroupCreateTask < Politburo::Resource::StateTask

          def met?(verification = false)
            logger.info("Searching for existing security group...") unless verification
            cloud_security_group = resource.cloud_security_group
            logger.info("Identified existing security group: #{cloud_security_group.group_id.cyan}") if (cloud_security_group) and (!verification)
            cloud_security_group
          end

          def verify_met?
            met?(true)
          end

          def meet
            cloud_security_group = resource.cloud_provider.create_security_group_for(resource)
            logger.info("Created new security group: #{cloud_security_group.group_id.cyan}") if (cloud_security_group)
            cloud_security_group        
          end
        end
      end
    end
  end
end