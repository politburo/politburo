describe Politburo::Resource::Cloud::Providers do

  context "class methods" do

    context "#for" do

      let(:provider_type) { :fakecloud }
      let(:provider_config) { { configuration: 'of some sort'} }
      let(:resource) { double("fake resource", :provider => provider_type, :provider_config => provider_config, :availability_zone => 'az-0')}
      let(:provider_instance) { Politburo::Resource::Cloud::Providers.for(resource) }

      let(:fake_cloud_provider_class) do
        Class.new()
      end

      before :each do
        Politburo::Resource::Cloud::Providers.stub(:provider_types).and_return({ :fakecloud => fake_cloud_provider_class })
        fake_cloud_provider_class.stub(:for).with(resource).and_return(:provider_instance)
      end

      it "should use the provider types hash to pick the provider to use" do
        Politburo::Resource::Cloud::Providers.should_receive(:provider_types).and_return({ :fakecloud => fake_cloud_provider_class })
        fake_cloud_provider_class.should_receive(:for).with(resource).and_return(:provider_instance)
        provider_instance.should_not be_nil
      end

    end

  end

end
