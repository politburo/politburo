Politburo::Resource::Facet.class_eval do

  inherits :provider
  inherits :provider_config
  inherits :region

  requires :provider

end