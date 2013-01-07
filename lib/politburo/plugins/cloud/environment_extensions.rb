Politburo::Resource::Environment.class_eval do
  attr_accessor :provider
  attr_accessor :provider_config
  attr_accessor :region

  requires :provider
  
end