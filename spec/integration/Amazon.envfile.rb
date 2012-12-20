environment(name: 'Amazon', description: "Amazon integration test environment",
  provider: :aws, 
  provider_config: { aws_access_key_id: ENV['AWS_ACCESS_KEY_ID'], aws_secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'] } ) do

  { "US West" => :'us-west-1', "EU West" => :'eu-west-1', "APAC Sydney" => :'ap-southeast-2' }.each_pair do 
    | name, region |

    facet(name: name, region: region) do
      node(name: "Primary host in zone") do
      end
    end
  end

end
