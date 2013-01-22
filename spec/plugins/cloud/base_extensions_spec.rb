describe Politburo::Plugins::Cloud::BaseExtensions do
  let(:extended_class) {
    Class.new(Politburo::Resource::Base) {
      include Politburo::Plugins::Cloud::BaseExtensions
    }
  }

  let(:parent_resource) { Politburo::Resource::Base.new(name: 'Parent resource') }
  let(:resource) { extended_class.new(name: "Base resource") }

  before :each do
    parent_resource.add_child(resource)
  end

  context "#cloud_provider" do

    it "should use the Provider class to ask for the provider from the pool, based on the type and config" do
      Politburo::Plugins::Cloud::Providers.should_receive(:for).with(resource).and_return(:cloud_provider)

      resource.cloud_provider.should be :cloud_provider
    end
  end

end

