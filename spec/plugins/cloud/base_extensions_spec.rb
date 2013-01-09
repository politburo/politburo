describe Politburo::Resource::Base, "cloud extensions" do
  let(:parent_resource) { Politburo::Resource::Base.new(name: 'Parent resource') }
  let(:resource) { Politburo::Resource::Base.new(parent_resource: parent_resource, name: "Base resource") }

  context "#cloud_provider" do

    it "should use the Provider class to ask for the provider from the pool, based on the type and config" do
      Politburo::Plugins::Cloud::Providers.should_receive(:for).with(resource).and_return(:cloud_provider)

      resource.cloud_provider.should be :cloud_provider
    end
  end

end

