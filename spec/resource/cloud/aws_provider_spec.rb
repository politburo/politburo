describe Politburo::Resource::Cloud::AWSProvider do
  let(:config) { { :fake_config => 'something' } }
  let(:provider) { Politburo::Resource::Cloud::AWSProvider.new(config) }
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
    let(:node) { double("fake node", :name => 'name', :full_name => 'full name', :logger => logger, :server_creation_overrides => nil)}
    let(:servers) { double("fake servers container") }
    let(:server) { double("fake created server") }
    let(:image) { double("fake image", :id => 'ami-00000') }

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

      it "should merge the resource's region and provider_config" do
        Politburo::Resource::Cloud::AWSProvider.config_for(resource).should eq({ :provider => 'AWS', :region => 'az-0', :configuration => 'of some sort' })
      end

    end

  end

end
