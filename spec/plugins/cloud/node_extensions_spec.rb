describe Politburo::Resource::Node, "cloud extensions" do
  let(:parent_resource) { Politburo::Resource::Base.new(name: "Parent resource") }
  let(:node) { Politburo::Resource::Node.new(name: "Node resource") }

  before :each do
    parent_resource.add_child(node)
  end


  context "#provider" do

    it "should inherit provider" do
      parent_resource.should_receive(:provider).and_return(:simple)

      node.provider.should be :simple
    end

    it "should require a provider" do
      parent_resource.should_receive(:provider).and_return(nil)
      node.provider = nil
      node.should_not be_valid
    end

  end

  context "#provider_config" do

    it "should inherit provider_config" do
      parent_resource.should_receive(:provider_config).and_return(:config)

      node.provider_config.should be :config
    end

  end

  context "#region" do

    it "should inherit region" do
      parent_resource.should_receive(:region).and_return(:us_west_1)

      node.region.should be :us_west_1
    end

  end

  context "#cloud_provider" do

    it "should use the Provider class to ask for the provider from the pool, based on the type and config" do
      Politburo::Plugins::Cloud::Providers.should_receive(:for).with(node).and_return(:cloud_provider)

      node.cloud_provider.should be :cloud_provider
    end
  end

  context "#cloud_server" do
    let(:cloud_provider) { double("fake cloud provider") }

    before :each do
      node.should_receive(:cloud_provider).and_return(cloud_provider)
    end

    it "should use the cloud_provider to ask for the server for this node" do
      cloud_provider.should_receive(:find_server_for).with(node).and_return(:cloud_server)

      node.cloud_server.should be :cloud_server
    end
  end

  context "#server_creation_overrides" do

    it "should have an accessor for this property" do
      node.server_creation_overrides = { :availability_zone => 'us-west-1c'}
      node.server_creation_overrides.should eq ({ :availability_zone => 'us-west-1c'})
    end

  end



end