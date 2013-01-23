module Politburo
  module Plugins
    module Cloud
      module Tasks
        class KeyPairCreateTask < Politburo::Resource::StateTask

          def met?(verification = false)
            logger.info("Searching for existing key pair with name '#{resource.cloud_counterpart_name.cyan}' in region #{resource.region.to_s.cyan}...") unless verification
            cloud_key_pair = resource.cloud_key_pair

            if (cloud_key_pair)
              logger.info("Identified existing key pair: '#{resource.cloud_counterpart_name.cyan}' in region #{resource.region.to_s.cyan}") if (cloud_key_pair) and (!verification)
              if resource.private_key_path.exist?
                logger.info("Found existing private key file at: '#{resource.private_key_path.to_s.cyan}'.") unless verification
              else
                logger.error("Could not find existing private key file at: '#{resource.private_key_path.to_s.red}'!")
                raise "Key pair '#{resource.cloud_counterpart_name}' exists in the cloud but a matching private key file can't be found at: '#{resource.private_key_path.to_s}'. Manually delete the cloud key pair if you want it to be re-generated (be careful!) or provide the private key file - perhaps someone didn't check it in?"
              end
            end

            cloud_key_pair
          end

          def meet(try = 0)
            cloud_key_pair = nil
            if resource.private_key_path.exist?
              if resource.public_key_path.exist?
                logger.info("Importing public key at '#{resource.public_key_path.to_s.cyan}' as key pair '#{resource.cloud_counterpart_name.cyan}' in region #{resource.region.to_s.cyan}...")
                cloud_key_pair = resource.cloud_provider.compute_instance.key_pairs.create(name: resource.cloud_counterpart_name, public_key: resource.public_key_path.read)
              else
                logger.error("No existing key pair with name '#{resource.cloud_counterpart_name.cyan}' in region #{resource.region.to_s.cyan}, but found existing private key file at: '#{resource.private_key_path.to_s.cyan}' - will abort to avoid accidental override of private keys. You may delete the existing private key (be careful) to allow the key pair to be re-generated, or alternatively if you have the matching public key provide it as '#{resource.public_key_path.to_s.cyan}'.")
                raise "Found existing private key file at: '#{resource.private_key_path.to_s}' with no matching key pair in the cloud."
              end
            else
              logger.info("Creating new key pair with name '#{resource.cloud_counterpart_name.cyan}' in region #{resource.region.to_s.cyan}, will store private key at: '#{resource.private_key_path.to_s.cyan}'...")
              cloud_key_pair = resource.cloud_provider.compute_instance.key_pairs.create(name: resource.cloud_counterpart_name)
              cloud_key_pair.write(resource.private_key_path.to_s)
            end

            cloud_key_pair
          end
        end
      end
    end
  end
end