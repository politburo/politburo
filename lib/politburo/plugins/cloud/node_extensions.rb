Politburo::Resource::Node.class_eval do
  inherits :provider
  inherits :provider_config
  inherits :region

  requires :provider

  def cloud_server
    @cloud_server.nil? ? ( @cloud_server = cloud_provider.find_server_for(self) ) : (@cloud_server = @cloud_server.reload )
  end
  
end
