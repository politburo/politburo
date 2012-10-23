describe Politburo::Tasks::RemoteTask do

  let(:node) { Politburo::Resource::Node.new(name: "Node resource") }
  let(:task) { Politburo::Tasks::RemoteTask.new(node: node, command: "remote command", met_test: "remote command that returns true if met") }

  it "should initialize correctly" do
    task.should_not be_nil
    task.node.should be node
  end

  it { task.should be_a Politburo::Dependencies::Task }

  context "#met?" do

    it "should return true when met_test evaluates to true when executed remotely" do
      fail("todo")
    end

    it "should return false when met_test evaluates to false when executed remotely" do
      fail("todo")
    end

  end
end