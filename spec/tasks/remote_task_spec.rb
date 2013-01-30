describe Politburo::Tasks::RemoteTask do

  let(:session) { double("fake ssh session") }
  let(:session_pool) { double("session pool") }
  let(:channel) { double("fake ssh channel", :wait => true) }

  let(:node) { Politburo::Resource::Node.new(name: "Node resource", host: 'localhost') }

  let(:state) { Politburo::Resource::State.new(name: "state") }

  let(:remote_command) { double("remote command", :kind_of? => true, :execution_result => {} ) }
  let(:remote_met_test_command) { double("remote met test command", :kind_of? => true, :execution_result => {}) }

  let(:task) { Politburo::Tasks::RemoteTask.new(name: 'Test Task', command: remote_command, met_test_command: remote_met_test_command) }

  before :each do
    node.add_child(state)
    state.add_child(task)

    node.stub(:session_pool).and_return(session_pool)
    session_pool.stub(:take).and_yield(session)
  end

  it "should initialize correctly" do
    task.should_not be_nil
    task.node.should be node
    task.command.should be remote_command
    task.met_test_command.should be remote_met_test_command
  end

  it { task.should be_a Politburo::Dependencies::Task }

  context "#met?" do

    before :each do
      session.should_receive(:open_channel).and_yield(channel).and_return(channel)
    end

    it "should return true when met_test_command executes with successful outcome" do
      remote_met_test_command.should_receive(:execute).and_return({ exit_code: "0" })
      channel.should_receive(:wait)

      task.should be_met
    end

    it "should return false when met_test_command executes with unsucessful outcome" do
      remote_met_test_command.should_receive(:execute).and_return(nil)
      channel.should_receive(:wait)

      task.should_not be_met
    end

  end

  context "#meet" do

    before :each do
      session.should_receive(:open_channel).and_yield(channel).and_return(channel)
    end

    it "should return true when command executes with successful outcome" do
      remote_command.should_receive(:execute).and_return({ exit_code: "0" })

      task.meet.should_not be_nil
    end

    it "should return false when command executes with unsucessful outcome" do
      remote_command.should_receive(:execute).and_return(nil)

      task.meet.should be_nil
    end

  end  
end