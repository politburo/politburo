describe Politburo::Plugins::Cloud::AWSProvider do
  let(:config) { { :fake_config => 'something' } }
  let(:provider) { Politburo::Plugins::Cloud::AWSProvider.new(config) }
  let(:compute_instance) { double("fake compute instance")}

  before :each do
    provider.stub(:compute_instance).and_return(compute_instance)
  end

  context "#find_server_for" do
    let(:node) { double("fake node", :full_name => 'full name')}

    let(:matching_server) { double("fake server", :tags => { "another tag" => "tag value", "politburo:full_name" => 'full name'}, :state => 'not terminated') }
    let(:matching_server_that_was_terminated) { double("fake server", :tags => { "another tag" => "tag value", "politburo:full_name" => 'full name'}, :state => 'terminated') }
    let(:non_matching_server) { double("fake server", :tags => { "another tag" => "tag value", "politburo:full_name" => 'a different full name'}, :state => 'not terminated') }

    before :each do
      compute_instance.stub(:servers).and_return(servers)
    end

    context "with one matching server" do
      let(:servers) { [ non_matching_server, non_matching_server, matching_server, non_matching_server, matching_server_that_was_terminated ]}

      it "should enumerate all the servers and find the one that has a politburo:full_name tag that matches the resource" do
        compute_instance.should_receive(:servers).and_return(servers)
        provider.find_server_for(node).should be matching_server
      end
    end

    context "with more than one matching server" do
      let(:servers) { [ matching_server, non_matching_server, matching_server, non_matching_server, matching_server_that_was_terminated  ]}

      it "should raise an error if more than one server was found" do
        compute_instance.should_receive(:servers).and_return(servers)
        lambda { provider.find_server_for(node) }.should raise_error /More than one cloud server tagged with the full name: 'full name'. Matching servers: \[.*\]/
      end

    end

    context "with no matching servers" do
    let(:servers) { [ non_matching_server, non_matching_server, non_matching_server, non_matching_server, matching_server_that_was_terminated  ]}

      it "should return nil" do
        compute_instance.should_receive(:servers).and_return(servers)
        provider.find_server_for(node).should be_nil
      end

    end

  end

  context "#create_server_for" do
    let(:logger) { double("fake logger", :info => true, :debug => true)}
    let(:node) { double("fake node", :name => 'name', :full_name => 'full name', :logger => logger, :server_creation_overrides => nil, :default_security_group => security_group_resource, :key_pair => key_pair_resource)}
    let(:servers) { double("fake servers container") }
    let(:server) { double("fake created server") }
    let(:image) { double("fake image", :id => 'ami-00000') }

    let(:security_group_resource) { double("fake security group resource", cloud_security_group: cloud_security_group) }
    let(:cloud_security_group) { double("fake cloud security group", name: 'security_group_name') }

    let(:key_pair_resource) { double("key pair resource", cloud_counterpart_name: 'key pair name', private_key_content: 'key content') }

    before :each do
      provider.compute_instance.stub(:servers).and_return(servers)      
      provider.stub(:flavor_for).and_return(:cookies_and_cream)
      provider.stub(:image_for).and_return(:image_selector)
      provider.stub(:find_image).with(:image_selector).and_return(image)

      servers.stub(:create).with(kind_of(Hash)).and_return(server)
    end

    it "should use the compute instance to create the server" do
      provider.compute_instance.should_receive(:servers).and_return(servers)
      servers.should_receive(:create).with(anything).and_return(server)      

      provider.create_server_for(node).should be server
    end

    it "should use #flavor_for to set the flavor for the server" do
      provider.should_receive(:flavor_for).and_return(:cookies_and_cream)

      servers.should_receive(:create) do | properties | 
        properties[:flavor_id].should be :cookies_and_cream
        server 
      end

      provider.create_server_for(node).should be server
    end

    it "should use #image_for to find the flavor for the server" do
      provider.should_receive(:image_for).and_return(:image_selector)
      provider.should_receive(:find_image).with(:image_selector).and_return(image)
      image.should_receive(:id).and_return('ami-00000')

      servers.should_receive(:create) do | properties | 
        properties[:image_id].should eq 'ami-00000'
        server 
      end

      provider.create_server_for(node).should be server
    end

    it "should use default_security_group to identify the first additional security group for the cloud server" do
      node.should_receive(:default_security_group).and_return(security_group_resource)
      security_group_resource.should_receive(:cloud_security_group).and_return(cloud_security_group)
      cloud_security_group.should_receive(:name).and_return('security_group_name')

      servers.should_receive(:create) do | properties | 
        properties[:groups].should include 'default'
        properties[:groups].should include 'security_group_name'
        server 
      end

      provider.create_server_for(node).should be server
    end

     it "should use key_pair to identify the key to use for the server" do
      node.should_receive(:key_pair).and_return(key_pair_resource)
      key_pair_resource.should_receive(:cloud_counterpart_name).and_return('key pair name')

      servers.should_receive(:create) do | properties | 
        properties[:key_name].should eq 'key pair name'
        server 
      end

      provider.create_server_for(node).should be server
    end

    it "should use #full_name to set the full name and name of the server" do
      servers.should_receive(:create) do | properties | 
        properties[:tags].should eq({'politburo:full_name' => 'full name', 'Name' => 'full name' })
        server 
      end

      provider.create_server_for(node).should be server
    end

    it "should merge in the node's server_creation_overrides" do
      node.should_receive(:server_creation_overrides).and_return(availability_zone: 'us-west-1c')

      servers.should_receive(:create) do | properties | 
        properties[:availability_zone].should eq 'us-west-1c'
        server
      end

      provider.create_server_for(node).should be server      
    end
  end

  context "security groups" do
    let(:parent_resource) { double("parent resource", full_name: :parent_resource_full_name) }
    let(:security_group_resource) { double("security group resource", cloud_counterpart_name: :security_group_resource_counterpart_name, parent_resource: parent_resource) }
    let(:security_group_collection) { double("security group collection") }
    let(:cloud_security_group) { double("cloud security group") }

    context "#find_security_group_for" do

      it "should retrieve the cloud security group for the security group resource" do
        compute_instance.should_receive(:security_groups).and_return(security_group_collection)
        security_group_collection.should_receive(:get).with(:security_group_resource_counterpart_name).and_return(cloud_security_group)

        provider.find_security_group_for(security_group_resource).should be cloud_security_group
      end

    end

    context "#create_security_group_for" do

      it "should create the cloud security group for the security group resource" do
        compute_instance.should_receive(:security_groups).and_return(security_group_collection)
        security_group_collection.should_receive(:create).with(name: :security_group_resource_counterpart_name, description: "Default security group for parent_resource_full_name. Automatically created by Politburo.").and_return(cloud_security_group)

        provider.create_security_group_for(security_group_resource).should be cloud_security_group
      end

    end

  end
  context "key pairs" do
    let(:parent_resource) { double("parent resource", full_name: :parent_resource_full_name) }
    let(:key_pair_resource) { double("key pair resource", cloud_counterpart_name: :key_pair_resource_counterpart_name, parent_resource: parent_resource) }
    let(:key_pair_collection) { double("key pair collection") }
    let(:cloud_key_pair) { double("cloud key pair") }

    context "#find_key_pair_for" do

      it "should retrieve the cloud key pair for the key pair resource" do
        compute_instance.should_receive(:key_pairs).and_return(key_pair_collection)
        key_pair_collection.should_receive(:get).with(:key_pair_resource_counterpart_name).and_return(cloud_key_pair)

        provider.find_key_pair_for(key_pair_resource).should be cloud_key_pair
      end

    end

    # context "#create_key_pair_for" do

    #   it "should create the cloud key pair for the key pair resource" do
    #     compute_instance.should_receive(:key_pairs).and_return(key_pair_collection)
    #     key_pair_collection.should_receive(:create).with(name: :key_pair_resource_counterpart_name, description: "Default key pair for parent_resource_full_name. Automatically created by Politburo.").and_return(cloud_key_pair)

    #     provider.create_key_pair_for(key_pair_resource).should be cloud_key_pair
    #   end

    # end

  end

  context "#images" do
    let(:images) { double("fake images list") }

    it "should cache the compute instances images list" do
      compute_instance.should_receive(:images).and_return(images)

      provider.images.should be images
      provider.images.should be images # Still the same
    end
  end

  context "#find_image" do

    context "when a symbol is provided" do
      it "should assume it is a image id" do
        provider.should_receive(:find_images_by_attributes).with(id: "ami-00000").and_return([ :image ])
        provider.find_image(:'ami-00000').should be :image
      end
    end

    context "when a string is provided" do
      it "should assume it is a image id" do
        provider.should_receive(:find_images_by_attributes).with(id: "ami-00000").and_return([ :image ])
        provider.find_image('ami-00000').should be :image
      end
    end

    context "when a regular expression is provided" do
      it "should use it to match by name" do
        provider.should_receive(:find_images_by_attributes).with(name: /name regexp/).and_return([ :image ])
        provider.find_image(/name regexp/).should be :image
      end
    end

    context "when a hash is provided" do
      it "should use it as matching argument" do
        provider.should_receive(:find_images_by_attributes).with({ find: 'by attributes' }).and_return([ :image ])
        provider.find_image(find: 'by attributes').should be :image
      end
    end

    context "when no images are found" do
      it "should raise an error" do
        provider.should_receive(:find_images_by_attributes).with(anything).and_return([])
        lambda { provider.find_image('non existant image') }.should raise_error "Could not find an image that matches the attributes: {:id=>\"non existant image\"}."
      end
    end

    context "when more than one image is found" do
      it "should return nil" do
        provider.should_receive(:find_images_by_attributes).with(anything).and_return([:image, :image, :image])
        lambda { provider.find_image(/matches many images/) }.should raise_error "Ambiguous image identifier. More than one image matches the attributes: {:name=>/matches many images/}. Matches: [:image, :image, :image]"
      end
    end
  end

  context "#find_images_by_attributes" do
    let(:images) { [ :matching_image, :non_matching_image, :another_matching_image ] }

    it "should iterate over images and attempt matching to attributes, collecting the matches" do
      provider.should_receive(:images).and_return(images)

      Politburo::Resource::Searchable.should_receive(:matches?).with(:matching_image, :attributes).and_return true
      Politburo::Resource::Searchable.should_receive(:matches?).with(:non_matching_image, :attributes).and_return false
      Politburo::Resource::Searchable.should_receive(:matches?).with(:another_matching_image, :attributes).and_return true

      provider.find_images_by_attributes(:attributes).should eq [ :matching_image, :another_matching_image ]
    end
  end

  context "#default_flavor" do
    it { provider.default_flavor.should eq "m1.small" }
  end

  context "#default_image" do
    it { provider.default_image.should be_a Hash }
  end

  context "class methods" do

    let(:provider_config) { { configuration: 'of some sort'} }
    let(:resource) { double("fake resource", :provider_config => provider_config, :region => 'az-0')}

    context "#for" do
      let(:provider_instance) { Politburo::Plugins::Cloud::AWSProvider.for(resource) }

      before :each do
        Politburo::Plugins::Cloud::AWSProvider.stub(:config_for).with(resource).and_return(:a_config_for_the_resource)
      end

      it "should use the resource to build a configuration and pool the instance require for it" do
        Politburo::Plugins::Cloud::AWSProvider.should_receive(:config_for).with(resource).and_return(:a_config_for_the_resource)
        Politburo::Plugins::Cloud::AWSProvider.should_receive(:new).with(:a_config_for_the_resource) { double("a new provider instance" )}

        provider_instance.should_not be_nil
        Politburo::Plugins::Cloud::AWSProvider.for(resource).should be provider_instance
      end

    end

    context "#config_for" do

      it "should merge the resource's region and provider_config" do
        Politburo::Plugins::Cloud::AWSProvider.config_for(resource).should eq({ :provider => 'AWS', :region => 'az-0', :configuration => 'of some sort' })
      end

    end

  end

end
