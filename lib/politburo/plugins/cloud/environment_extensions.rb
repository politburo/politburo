Politburo::Resource::Environment.class_eval do
  attr_accessor :provider
  attr_accessor :provider_config
  attr_accessor :region

  requires :provider
  
  attr_with_default(:private_keys_path) { root.cli.private_keys_path }
end

Politburo::Resource::EnvironmentContext.class_eval do
  def security_group(attributes, &block)
    lookup_or_create_resource(::Politburo::Plugins::Cloud::SecurityGroup, attributes, &block)
  end

  def key_pair(attributes, &block)
    lookup_or_create_resource(::Politburo::Plugins::Cloud::KeyPair, attributes, &block)
  end
end