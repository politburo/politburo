describe Politburo::Resource::Cloud::AWSProvider do
  let(:config) { { :fake_config => 'something' } }
  let(:provider) { Politburo::Resource::Cloud::AWSProvider.new(config) }

  context "class methods" do

    let(:provider_config) { { configuration: 'of some sort'} }
    let(:resource) { double("fake resource", :provider_config => provider_config, :availability_zone => 'az-0')}

    context "#for" do
      let(:provider_instance) { Politburo::Resource::Cloud::AWSProvider.for(resource) }

      before :each do
        Politburo::Resource::Cloud::AWSProvider.stub(:config_for).with(resource).and_return(:a_config_for_the_resource)
      end

      it "should use the resource to build a configuration and pool the instance require for it" do
        Politburo::Resource::Cloud::AWSProvider.should_receive(:config_for).with(resource).and_return(:a_config_for_the_resource)
        Politburo::Resource::Cloud::AWSProvider.should_receive(:new).with(:a_config_for_the_resource) { double("a new provider instance" )}

        provider_instance.should_not be_nil
        Politburo::Resource::Cloud::AWSProvider.for(resource).should be provider_instance
      end

    end

    context "#config_for" do

      it "should merge the resource's availability_zone and provider_config" do
        Politburo::Resource::Cloud::AWSProvider.config_for(resource).should eq({ :provider => 'AWS', :availability_zone => 'az-0', :configuration => 'of some sort' })
      end

    end

  end
end
