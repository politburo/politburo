describe Politburo::Resource::Cloud::AWSProvider do
  let(:config) { { :fake_config => 'something' } }
  let(:provider) { Politburo::Resource::Cloud::AWSProvider.new(config) }
  let(:compute_instance) { double("fake compute instance")}

  before :each do
    provider.stub(:compute_instance).and_return(compute_instance)
  end

  context "#server_for" do
    let(:node) { double("fake node", :full_name => 'full name')}

    let(:matching_server) { double("fake server", :tags => { "another tag" => "tag value", "politburo:full_name" => 'full name'}) }
    let(:non_matching_server) { double("fake server", :tags => { "another tag" => "tag value", "politburo:full_name" => 'a different full name'}) }

    before :each do
      compute_instance.stub(:servers).and_return(servers)
    end

    context "with one matching server" do
      let(:servers) { [ non_matching_server, non_matching_server, matching_server, non_matching_server ]}

      it "should enumerate all the servers and find the one that has a politburo:full_name tag that matches the resource" do
        compute_instance.should_receive(:servers).and_return(servers)
        provider.server_for(node).should be matching_server
      end
    end

    context "with more than one matching server" do
      let(:servers) { [ matching_server, non_matching_server, matching_server, non_matching_server ]}

      it "should raise an error if more than one server was found" do
        compute_instance.should_receive(:servers).and_return(servers)
        lambda { provider.server_for(node) }.should raise_error /More than one cloud server tagged with the full name: 'full name'. Matching servers: \[.*\]/
      end

    end

    context "with no matching servers" do
    let(:servers) { [ non_matching_server, non_matching_server, non_matching_server, non_matching_server ]}

      it "should return nil" do
        compute_instance.should_receive(:servers).and_return(servers)
        provider.server_for(node).should be_nil
      end

    end

  end

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
        Politburo::Resource::Cloud::AWSProvider.config_for(resource).should eq({ :provider => 'AWS', :region => 'az-0', :configuration => 'of some sort' })
      end

    end

  end

end
