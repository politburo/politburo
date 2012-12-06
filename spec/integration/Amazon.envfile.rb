environment(name: 'Amazon', description: "Amazon integration test environment", provider: :amazon_web_services) do

  { "US West" => :'us-west-1', "US East" => :'us-east-1', "APAC Sydney" => :'ap-southeast-2' }.each_pair do 
    | name, availability_zone |

    facet(name: name, availability_zone: availability_zone) do
      node(name: "Primary host in zone") do
      end
    end
  end

end
