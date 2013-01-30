describe Politburo::Plugins::Cloud::Tasks::StartTask do

  let(:provider) { double("cloud provider") }
  let(:node) { Politburo::Resource::Node.new(name: "Node resource") }

  let(:state) { node.context.define { state(:started) {} }.state(:started) }
  let(:task) { Politburo::Plugins::Cloud::Tasks::StartTask.new(name: 'Start') }

  let(:cloud_server) { double("cloud server", display_name: 'server.display.name') }

  before :each do
    node.stub(:cloud_provider).and_return(provider)

    state.add_child(task)
    cloud_server.stub(:reload).and_return(cloud_server)
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

      context "when it is ready" do
        before :each do
          cloud_server.should_receive(:ready?).and_return(true)
        end

        it "and it is sshable, should return true" do
          cloud_server.should_receive(:sshable?).and_return(true)

          task.should be_met
        end

        it "and it is not sshable, should return false" do
          cloud_server.should_receive(:sshable?).and_return(false)

          task.should_not be_met
        end

      end

      it "and it is not ready, should return false" do
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
      task.stub(:sshable?).and_return(true)

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

      it "and times out waiting for stop, it should raise an error" do
        cloud_server.should_receive(:wait_for).and_yield.and_return(false)

        lambda { task.meet }.should raise_error "Timed out while waiting for server server.display.name to fully stop."
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

    context "when waiting for server to start" do

      before :each do
        cloud_server.should_receive(:state).twice.and_return("pending")
      end

      it "should wait until it is ready" do
        cloud_server.should_receive(:wait_for).twice.and_yield.and_return({:duration=>19.0})

        # The following expectations are actually on the _server_. 
        # However, rspec doesn't seem to let you change the yield context
        task.should_receive(:ready?).and_return(true)

        task.meet
      end

      it "if it times out waiting for stop, it should raise an error" do
        cloud_server.should_receive(:wait_for).and_yield.and_return(false)

        lambda { task.meet }.should raise_error "Timed out while waiting for server server.display.name to become available."
      end

    end

    context "when waiting for server to become sshable" do
      before :each do
        cloud_server.stub(:state).twice.and_return("running")
      end

      it "should wait until it is sshable" do
        cloud_server.should_receive(:wait_for).twice.and_yield.and_return({:duration=>19.0})
        
        # The following expectation are actually on the _server_. 
        # However, rspec doesn't seem to let you change the yield context
        task.should_receive(:sshable?).and_return(true)      

        task.meet
      end

      it "if it times out waiting for stop, it should raise an error" do
        cloud_server.should_receive(:wait_for).and_yield.and_return({:duration=>19.0})
        cloud_server.should_receive(:wait_for).and_yield.and_return(false)

        lambda { task.meet }.should raise_error "Timed out while waiting for ssh access to server server.display.name."
      end

    end

  end
end
