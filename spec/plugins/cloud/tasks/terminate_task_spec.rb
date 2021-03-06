describe Politburo::Plugins::Cloud::Tasks::TerminateTask do

  let(:provider) { double("cloud provider") }
  let(:node) { Politburo::Resource::Node.new(name: "Node resource") }

  let(:state) { node.context.define { state(:started) {} }.state(:started) }
  let(:task) { Politburo::Plugins::Cloud::Tasks::TerminateTask.new(name: 'Terminate') }

  let(:cloud_server) { double("cloud server", display_name: 'dnsname.ec2.amazon.com') }

  before :each do
    state.add_child(task)
    node.stub(:cloud_provider).and_return(provider)
  end

  context "#met?" do
    context "when the server has not been created yet" do
      it "should return true" do
        node.should_receive(:cloud_server).and_return(nil)
        task.should be_met
      end
    end

    context "when the server has been created" do

      before :each do
        node.should_receive(:cloud_server).and_return(cloud_server)
      end

      %w(terminated).each do | already_terminated_state | 
        it "and it is #{already_terminated_state}, should return true" do
          cloud_server.should_receive(:state).twice.and_return(already_terminated_state)
          task.should be_met
        end

      end

      %w(pending starting started stopping stopped).each do | not_yet_terminated_state | 
        it "and it is #{not_yet_terminated_state}, should return false" do
          cloud_server.should_receive(:state).and_return(not_yet_terminated_state)
          task.should_not be_met
        end
      end

    end
    
  end

  context "#meet" do
    before :each do
      node.should_receive(:cloud_server).and_return(cloud_server)

      cloud_server.stub(:destroy)
      cloud_server.stub(:wait_for).and_yield

      # The following expectation is actually on the _server_. 
      # However, rspec doesn't seem to let you change the yield context
      task.stub(:state).and_return("terminated")
    end

    context "when not terminated" do
      before :each do
        cloud_server.should_receive(:state).and_return("running")
      end

      it "should send destroy to the server" do
        cloud_server.should_receive(:destroy)

        task.meet
      end

    end

    it "should wait for the server to terminate" do
      cloud_server.should_receive(:state).and_return("stopping")
      cloud_server.should_receive(:wait_for).and_yield

      # The following expectation is actually on the _server_. 
      # However, rspec doesn't seem to let you change the yield context
      task.should_receive(:state).and_return("terminated")      

      task.meet
    end

  end
end
