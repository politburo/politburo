describe Politburo::Tasks::StartTask do

  let(:provider) { double("cloud provider") }
  let(:node) { Politburo::Resource::Node.new(name: "Node resource") }

  let(:state) { node.state(:started) }
  let(:task) { Politburo::Tasks::StartTask.new(name: 'Start', resource_state: state) }

  let(:cloud_server) { double("cloud server", display_name: 'server.display.name') }

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

      before :each do
        node.should_receive(:cloud_server).and_return(cloud_server)
      end

      it "and it is ready, should return true" do
        cloud_server.should_receive(:ready?).and_return(true)
        task.should be_met
      end

      it "and it is not ready, should return true" do
        cloud_server.should_receive(:ready?).and_return(false)
        task.should_not be_met
      end

    end
    
  end

  context "#meet" do

    before :each do
      node.stub(:cloud_server).and_return(cloud_server)

      cloud_server.stub(:start).and_return(true)
      # The following expectation is actually on the _server_. 
      # However, rspec doesn't seem to let you change the yield context
      task.stub(:ready?).and_return(true)

      cloud_server.stub(:wait_for).and_yield.and_return({:duration=>5.0})
    end

    context "when the server is stopping" do
      before :each do
        cloud_server.should_receive(:state).and_return("stopping")
      end

      it "should wait until it stopped" do
        cloud_server.should_receive(:state).and_return("stopping")
        cloud_server.should_receive(:wait_for).and_yield.and_return({:duration=>27.0})
        # The following expectation is actually on the _server_. 
        # However, rspec doesn't seem to let you change the yield context
        task.should_receive(:state).and_return("stopped")

        cloud_server.should_receive(:wait_for).and_yield.and_return({:duration=>16.0})

        task.meet
      end
    end

    context "when the server is stopped" do
      before :each do
        cloud_server.should_receive(:state).twice.and_return("stopped")
      end

      it "should start it" do
        cloud_server.should_receive(:start).and_return(true)

        task.meet
      end
    end

    it "should wait until it started" do
      cloud_server.should_receive(:state).twice.and_return("pending")
      cloud_server.should_receive(:wait_for).and_yield.and_return({:duration=>19.0})

      # The following expectation is actually on the _server_. 
      # However, rspec doesn't seem to let you change the yield context
      task.should_receive(:ready?).and_return(true)

      task.meet
    end
  end
end
