describe Politburo::Plugins::Cloud::SecurityGroup do

  let(:parent_resource) { Politburo::Resource::Base.new(name: "Parent resource") }
  let(:security_group) { Politburo::Plugins::Cloud::SecurityGroup.new(name: "Security group resource") }

  before :each do
    parent_resource.add_child(security_group)
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
