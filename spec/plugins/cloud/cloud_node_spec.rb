describe Politburo::Plugins::Cloud::Node do
  let(:parent_resource) { Politburo::Resource::Base.new(name: "Parent resource") }
  let(:node) { Politburo::Plugins::Cloud::Node.new(name: "Node resource") }

  before(:all) do
    Politburo::Resource::Base.class_eval { include Politburo::Plugins::Cloud::BaseExtensions }
  end

  before :each do
    parent_resource.add_child(node)
  end

  context "#create_session" do
    let(:cloud_server) { double("fake cloud server") }

    it "should use the cloud server to create the ssh session" do
      node.should_receive(:cloud_server).and_return(cloud_server)
      cloud_server.should_receive(:create_ssh_session).and_return(:ssh_session)

      node.create_session.should be :ssh_session
    end
  end

  context "#host" do
    let(:cloud_server) { double("fake cloud server") }

    it "should default to using the cloud server's public dns name'" do
      node.should_receive(:cloud_server).and_return(cloud_server)
      cloud_server.should_receive(:dns_name).and_return(:dns_name)

      node.host.should be :dns_name
      node.host = :override
      node.host.should be :override
    end
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

    it "should require region" do
      parent_resource.stub(:region).and_return(nil)
      parent_resource.stub(:provider).and_return(:aws)

      node.region.should be nil

      node.should_not be_valid
    end

  end

  context "#key_pair" do
    let(:default_key_pair_for_region_context) { double("context for default keypair", receiver: :default_key_pair_for_region) }

    before do
      parent_resource.stub(:key_pair).and_return(nil)
    end

    it "should default to locating one up the tree" do
      node.stub(:region).and_return(:region)
      node.context.should_receive(:lookup).with(name: 'Default Key Pair for region', class: Politburo::Plugins::Cloud::KeyPair, region: :region).and_return(default_key_pair_for_region_context)

      node.key_pair.should be :default_key_pair_for_region
    end

    it "should inherit the keypair if it was set up the hierarchy" do
      parent_resource.should_receive(:key_pair).and_return(:parent_key_pair)

      node.key_pair.should be :parent_key_pair
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
    let(:cloud_server) { double("fake cloud server") }
    let(:key_pair_resource) { double("key pair resource", private_key_content: 'key content') }

    before :each do
      node.stub(:cloud_provider).and_return(cloud_provider)
      node.stub(:key_pair).and_return(key_pair_resource)

      cloud_provider.stub(:find_server_for).with(node).and_return(cloud_server)
      cloud_server.stub(:'private_key=').with(anything)
    end

    it "should use the cloud_provider to ask for the server for this node" do
      node.should_receive(:cloud_provider).and_return(cloud_provider)
      cloud_provider.should_receive(:find_server_for).with(node).and_return(cloud_server)

      node.cloud_server.should be cloud_server
    end

    it "should set the private key on the server" do
      node.should_receive(:key_pair).and_return(key_pair_resource)
      key_pair_resource.should_receive(:private_key_content).and_return('key content')
      cloud_server.should_receive(:'private_key=').with('key content')

      node.cloud_server.should be cloud_server
    end
  end

  context "#default_security_group" do
    it "should have a default security group attribute" do
      node.default_security_group = :my_security_group

      node.default_security_group.should be :my_security_group
    end
  end

  context "#server_creation_overrides" do

    it "should have an accessor for this property" do
      node.server_creation_overrides = { :availability_zone => 'us-west-1c'}
      node.server_creation_overrides.should eq ({ :availability_zone => 'us-west-1c'})
    end

  end



end