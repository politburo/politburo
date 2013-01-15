module Politburo
  module Plugins
    module Cloud
      module Tasks
        class SecurityGroupTerminateTask < Politburo::Resource::StateTask

          def met?(verification = false)
            security_group = resource.cloud_security_group
            if security_group.nil?
              logger.info("No security group, so nothing to terminate.") unless verification
              return true
            end

            return false
          end

          def meet
            security_group = resource.cloud_security_group
            logger.info("Deleting security group: #{security_group.group_id.cyan}...")
            security_group.destroy

            true
          end
        end
      end
    end
  end
end
