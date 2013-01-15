describe Politburo::Plugins::Cloud::CloudResource do

  let(:parent_resource) { Politburo::Resource::Base.new(name: "Parent resource") }
  let(:cloud_resource) { Politburo::Plugins::Cloud::CloudResource.new(name: "Cloud resource") }

  before :each do
    parent_resource.add_child(cloud_resource)
  end

  context "#provider" do

    it "should inherit provider" do
      parent_resource.should_receive(:provider).and_return(:simple)

      cloud_resource.provider.should be :simple
    end

    it "should require a provider" do
      parent_resource.should_receive(:provider).and_return(nil)
      cloud_resource.provider = nil
      cloud_resource.should_not be_valid
    end

  end

  context "#region" do

    it "should inherit region" do
      parent_resource.should_receive(:region).and_return(:us_west_1)

      cloud_resource.region.should be :us_west_1
    end

  end

  context "#provider_config" do

    it "should inherit provider_config" do
      parent_resource.should_receive(:provider_config).and_return(:config)

      cloud_resource.provider_config.should be :config
    end

  end

end
