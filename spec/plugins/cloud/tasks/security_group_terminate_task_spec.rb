describe Politburo::Plugins::Cloud::Tasks::SecurityGroupTerminateTask do

  let(:provider) { double("cloud provider") }
  let(:security_group) { Politburo::Plugins::Cloud::SecurityGroup.new(name: "Security group resource") }
  let(:cloud_security_group) { double("cloud security group", group_id: 'sg-90210') }

  let(:state) { security_group.context.define { state(:started) {} }.state(:started) }
  let(:task) { Politburo::Plugins::Cloud::Tasks::SecurityGroupTerminateTask.new(name: 'Create security group') }

  before :each do
    security_group.stub(:cloud_provider).and_return(provider)
    state.add_child(task)
  end

  context "#met?" do
    context "when the security group has not been created yet" do
      it "should return true" do
        security_group.should_receive(:cloud_security_group).and_return(nil)
        task.should be_met
      end
    end

    context "when the security group has been created" do
      it "it should return false" do
        security_group.should_receive(:cloud_security_group).and_return(cloud_security_group)
        task.should_not be_met
      end
    end
    
  end

  context "#meet" do

    it "should send destroy to the security group" do
      security_group.should_receive(:cloud_security_group).and_return(cloud_security_group)
      cloud_security_group.should_receive(:destroy)

      task.meet
    end

  end
end
