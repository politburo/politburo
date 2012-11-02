describe Politburo::Tasks::RemoteTask do

  let(:session) { double("fake ssh session") }
  let(:channel) { double("fake ssh channel") }

  let(:node) { Politburo::Resource::Node.new(name: "Node resource") }


  let(:remote_command) { double("remote command") }
  let(:remote_met_test_command) { double("remote met test command") }

  let(:task) { Politburo::Tasks::RemoteTask.new(node: node, command: remote_command, met_test_command: remote_met_test_command) }

  it "should initialize correctly" do
    task.should_not be_nil
    task.node.should be node
    task.command.should be remote_command
    task.met_test_command.should be remote_met_test_command
  end

  it { task.should be_a Politburo::Dependencies::Task }

  context "#met?" do

    before :each do
      node.should_receive(:session).and_return(session)
      session.should_receive(:open_channel).and_yield(channel)
    end

    it "should return true when met_test_command executes with successful outcome" do
      remote_met_test_command.should_receive(:execute).and_return({ exit_code: "0" })

      task.met?
    end

    it "should return false when met_test_command execution with unsucessful outcome" do
      remote_met_test_command.should_receive(:execute).and_return(nil)

      task.met?
    end

  end
end