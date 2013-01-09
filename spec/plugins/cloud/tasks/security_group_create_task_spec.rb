describe Politburo::Plugins::Cloud::Tasks::SecurityGroupCreateTask do

  let(:provider) { double("cloud provider") }
  let(:security_group) { Politburo::Plugins::Cloud::SecurityGroup.new(name: "Security group resource") }
  let(:cloud_security_group) { double("cloud security group", group_id: 'sg-90210') }

  let(:state) { security_group.state(:started) }
  let(:task) { Politburo::Plugins::Cloud::Tasks::SecurityGroupCreateTask.new(name: 'Create security group', resource_state: state) }

  before :each do
    security_group.stub(:cloud_provider).and_return(provider)
  end

  context "#met?" do
    context "when the security group has not been created yet" do
      it "should return false" do
        security_group.should_receive(:cloud_security_group).and_return(nil)

        task.should_not be_met
      end
    end

    context "when the security group has been created" do

      before :each do
        security_group.should_receive(:cloud_security_group).and_return(cloud_security_group)
      end

      it "should return true" do
        task.should be_met
      end
    end
    
  end

  context "#verify_met?" do
    it "should delegate to met" do
      task.should_receive(:met?).with(true)

      task.verify_met?
    end
  end

  context "#meet" do

    it "should use create security group to return the server" do
      provider.should_receive(:create_security_group_for).with(security_group).and_return(cloud_security_group)

      task.meet.should be cloud_security_group
    end
  end
end
