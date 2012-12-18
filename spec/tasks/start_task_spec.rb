describe Politburo::Tasks::StartTask do

  let(:provider) { double("cloud provider") }
  let(:node) { Politburo::Resource::Node.new(name: "Node resource") }

  let(:state) { node.state(:started) }
  let(:task) { Politburo::Tasks::StartTask.new(name: 'Start', resource_state: state) }

  before :each do
    node.stub(:cloud_provider).and_return(provider)
  end

  context "#met?" do
    context "when the server has not been created yet" do
      it "should return false" do
        node.should_receive(:cloud_server).and_return(nil)
        task.should_not be_met
      end
    end

    context "when the server has been created" do
      let(:cloud_server) { double("cloud server") }

      before :each do
        node.should_receive(:cloud_server).twice.and_return(cloud_server)
      end

      context "and started" do

        it "should return true" do
          cloud_server.should_receive(:ready?).and_return(true)

          task.should be_met
        end

      end

      context "not yet started" do
        it "should return false" do
          cloud_server.should_receive(:ready?).and_return(false)

          task.should_not be_met
        end

      end
    end
  end

  context "#meet" do
    context "when the server has not been created yet" do
    end

    context "when the server has been created" do
      let(:cloud_server) { double("cloud server") }

      before :each do
      end

      context "and started" do
      end

      context "not yet started" do
      end
    end    
  end
end
