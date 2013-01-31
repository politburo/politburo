describe Politburo::Plugins::Cloud::Tasks::CloudResourceCreateTask do

  let(:provider) { double("cloud provider") }
  let(:cloud_resource) { Politburo::Plugins::Cloud::CloudResource.new(name: "Cloud resource") }
  let(:cloud_counterpart) { double("cloud counterpart", display_name: 'sg-90210') }

  let(:state) { cloud_resource.context.define { state(:started) {} }.state(:started) }
  let(:task) { Politburo::Plugins::Cloud::Tasks::CloudResourceCreateTask.new(name: 'Create cloud resource', noun: 'noun') }

  before :each do
    cloud_resource.stub(:cloud_provider).and_return(provider)
    state.add_child(task)
  end

  context "#met?" do
    context "when the security group has not been created yet" do
      it "should return false" do
        cloud_resource.should_receive(:cloud_counterpart).and_return(nil)

        task.should_not be_met
      end
    end

    context "when the security group has been created" do

      before :each do
        cloud_resource.should_receive(:cloud_counterpart).and_return(cloud_counterpart)
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
      cloud_resource.should_receive(:create_cloud_counterpart).and_return(cloud_counterpart)

      task.meet.should be cloud_counterpart
    end
  end
end
