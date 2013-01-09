Politburo::Resource::Base.class_eval do

  def cloud_provider
    Politburo::Plugins::Cloud::Providers.for(self)
  end

end

