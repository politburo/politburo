Politburo::Resource::Node.class_eval do
  inherits :provider
  inherits :provider_config
  inherits :region

  requires :provider
  requires :region

  attr_accessor :default_security_group

  attr_with_default(:key_pair) { self.context.lookup(name: "Default Key Pair for #{self.region}", class: Politburo::Plugins::Cloud::KeyPair, region: self.region).receiver }

  def cloud_server
    @cloud_server.nil? ? ( @cloud_server = cloud_provider.find_server_for(self) ) : (@cloud_server = @cloud_server.reload )
  end
  
end
