describe Politburo::Plugins::Cloud::SecurityGroup do

  let(:parent_resource) { Politburo::Resource::Base.new(name: "Parent resource") }
  let(:security_group) { Politburo::Plugins::Cloud::SecurityGroup.new(name: "Security group resource") }

  before :each do
    parent_resource.add_child(security_group)
  end

  context "#provider" do

    it "should inherit provider" do
      parent_resource.should_receive(:provider).and_return(:simple)

      security_group.provider.should be :simple
    end

    it "should require a provider" do
      parent_resource.should_receive(:provider).and_return(nil)
      security_group.provider = nil
      security_group.should_not be_valid
    end

  end

  context "#region" do

    it "should inherit region" do
      parent_resource.should_receive(:region).and_return(:us_west_1)

      security_group.region.should be :us_west_1
    end

  end

  context "#provider_config" do

    it "should inherit provider_config" do
      parent_resource.should_receive(:provider_config).and_return(:config)

      security_group.provider_config.should be :config
    end

  end
  
  context "cloud_security_group" do
    let(:provider) { double("provider") }

    it "should use the provider to return the appropriate security group" do
      security_group.should_receive(:cloud_provider).and_return(provider)
      provider.should_receive(:find_security_group_for).with(security_group).and_return(:cloud_security_group)

      security_group.cloud_security_group.should be :cloud_security_group
    end
  end

end
