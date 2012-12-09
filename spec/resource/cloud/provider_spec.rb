describe Politburo::Resource::Cloud::Provider do

  context "class methods" do

    context "#provider_for" do
      let(:provider_type) { :fakecloud }
      let(:provider_config) { { availability_zone: 'az-0'} }
      let(:another_provider_config) { { availability_zone: 'az-1'} }

      let(:provider_instance) { Politburo::Resource::Cloud::Provider.for(provider_type, provider_config) }
      let(:another_provider_instance) { Politburo::Resource::Cloud::Provider.for(provider_type, another_provider_config) }

      let(:fake_cloud_provider_class) do
        Class.new()
      end

      before :each do
        Politburo::Resource::Cloud::Provider.stub(:provider_types).and_return({ :fakecloud => fake_cloud_provider_class })
        fake_cloud_provider_class.stub(:new).with(provider_config).and_return(:provider_instance)
        fake_cloud_provider_class.stub(:new).with(another_provider_config).and_return(:another_provider_instance)
      end

      it "should use the provider types hash to pick the class to instantiate" do
        Politburo::Resource::Cloud::Provider.should_receive(:provider_types).and_return({ :fakecloud => fake_cloud_provider_class })
        fake_cloud_provider_class.should_receive(:new).with(provider_config).and_return(:provider_instance)

        provider_instance.should_not be_nil
      end

      it "should provide an instance for each specified provider type and config" do
        provider_instance.should_not be_nil
        another_provider_instance.should_not be_nil

        provider_instance.should be Politburo::Resource::Cloud::Provider.for(provider_type, provider_config)
        provider_instance.should_not be another_provider_instance
      end

    end

  end

end
