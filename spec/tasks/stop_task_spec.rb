describe Politburo::Tasks::StopTask do

  let(:provider) { double("cloud provider") }
  let(:node) { Politburo::Resource::Node.new(name: "Node resource") }

  let(:state) { node.state(:started) }
  let(:task) { Politburo::Tasks::StopTask.new(name: 'Stop', resource_state: state) }

  let(:cloud_server) { double("cloud server", id: "id-00000", dns_name: 'dnsname.ec2.amazon.com') }

  before :each do
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

      %w(stopped stopping).each do | already_stopped_state | 
        it "and it is #{already_stopped_state}, should return true" do
          cloud_server.should_receive(:state).twice.and_return(already_stopped_state)
          task.should be_met
        end

      end

      %w(pending starting started).each do | not_yet_stopped_state | 
        it "and it is #{not_yet_stopped_state}, should return false" do
          cloud_server.should_receive(:state).and_return(not_yet_stopped_state)
          task.should_not be_met
        end
      end

    end
    
  end

  context "#meet" do
    before :each do
      node.should_receive(:cloud_server).and_return(cloud_server)

      cloud_server.stub(:stop)
      cloud_server.stub(:wait_for).and_yield

      # The following expectation is actually on the _server_. 
      # However, rspec doesn't seem to let you change the yield context
      task.stub(:state).and_return("stopped")
    end

    it "should send stop to the server" do
      cloud_server.should_receive(:stop)

      task.meet
    end

    it "should wait for the server to stop" do
      cloud_server.should_receive(:wait_for).and_yield

      # The following expectation is actually on the _server_. 
      # However, rspec doesn't seem to let you change the yield context
      task.should_receive(:state).and_return("stopped")      

      task.meet
    end

  end
end
