describe Politburo::Resource::Cloud::Provider do

  let(:config) { { :fake_config => 'something' } }
  let(:provider) { Politburo::Resource::Cloud::Provider.new(config) }

  it "should initialize correctly" do
    provider.config.should be config
  end

  context "#compute_instance" do
    it "should use fog to instatiate a compute instance" do
      Fog::Compute.should_receive(:new).with(config).and_return(:fake_compute)

      provider.compute_instance.should be :fake_compute
    end
  end

  context "class methods" do

    context "#for" do

      let(:provider_config) { { configuration: 'of some sort'} }
      let(:resource) { double("fake resource", :provider_config => provider_config, :availability_zone => 'az-0')}
      let(:provider_instance) { Politburo::Resource::Cloud::Provider.for(resource) }

      before :each do
        Politburo::Resource::Cloud::Provider.stub(:config_for).with(resource).and_return(:a_config_for_the_resource)
      end

      it "should use the resource to build a configuration and pool the instance require for it" do
        Politburo::Resource::Cloud::Provider.should_receive(:config_for).with(resource).and_return(:a_config_for_the_resource)
        Politburo::Resource::Cloud::Provider.should_receive(:new).with(:a_config_for_the_resource) { double("a new provider instance" )}

        provider_instance.should_not be_nil
        Politburo::Resource::Cloud::Provider.for(resource).should be provider_instance
      end

    end

  end
end
