describe Politburo::Plugins::Cloud::Tasks::CloudResourceTerminateTask do

  let(:provider) { double("cloud provider") }
  let(:cloud_resource) { Politburo::Plugins::Cloud::CloudResource.new(name: "Cloud resource") }
  let(:cloud_counterpart) { double("cloud counterpart resource", display_name: 'resource#1') }

  let(:state) { cloud_resource.context.define { state(:started) {} }.state(:started) }
  let(:task) { Politburo::Plugins::Cloud::Tasks::CloudResourceTerminateTask.new(name: 'Delete cloud resource', noun: 'cloud resource') }

  before :each do
    cloud_resource.stub(:cloud_provider).and_return(provider)
    state.add_child(task)
  end

  context "#met?" do
    context "when the cloud resource has not been created yet" do
      it "should return true" do
        cloud_resource.should_receive(:cloud_counterpart).and_return(nil)
        task.should be_met
      end
    end

    context "when the cloud resource has been created" do
      it "it should return false" do
        cloud_resource.should_receive(:cloud_counterpart).and_return(cloud_counterpart)
        task.should_not be_met
      end
    end
    
  end

  context "#meet" do

    it "should send destroy to the cloud resource" do
      cloud_resource.should_receive(:cloud_counterpart).and_return(cloud_counterpart)
      cloud_counterpart.should_receive(:destroy)

      task.meet
    end

  end
end
