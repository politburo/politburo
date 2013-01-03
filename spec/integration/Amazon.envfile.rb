#
# Demonstrates an environment on Amazon AWS across multiple regions and availability zones
#
# To launch:
# > AWS_ACCESS_KEY_ID=<your key> AWS_SECRET_ACCESS_KEY=<your secret> politburo -e Amazon.envfile.rb Amazon#ready
#
# To terminate:
# > AWS_ACCESS_KEY_ID=<your key> AWS_SECRET_ACCESS_KEY=<your secret> politburo -e Amazon.envfile.rb Amazon#stop
# 
#
environment(name: 'Amazon', description: "Amazon integration test environment",
  provider: :aws, 
  provider_config: { aws_access_key_id: ENV['AWS_ACCESS_KEY_ID'], aws_secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'] } ) do

  { 
    "US East 1 (N. Virginia)"       => { region: 'us-east-1' }, 
    "US West 1 (N. California)"     => { region: 'us-west-1' }, 
    "US West 2 (Oregon)"            => { region: 'us-west-2' }, 
    "EU West 1 (Ireland)"           => { region: 'eu-west-1' }, 
    "APAC North East 1 (Tokyo)"     => { region: 'ap-northeast-1' },
    "APAC South East 1 (Singapore)" => { region: 'ap-southeast-1' },
    "APAC South East 2 (Sydney)"    => { region: 'ap-southeast-2', availability_zone: "ap-southeast-2b" },
    "South America 1 (Sao Paulo)"   => { region: 'sa-east-1' },
  }.each_pair do | name, options |
    region = options.delete(:region)

    facet(name: name, region: region) do
      node(name: "Primary host in zone", server_creation_overrides: options) do
        # state(:configured) {
        #   remote_task(
        #     name: 'install ruby',
        #     command: 'sudo apt-get install ruby', 
        #     met_test_command: 'which ruby') { }
        # }
      end
    end
  end

end
