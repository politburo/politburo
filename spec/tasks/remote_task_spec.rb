describe Politburo::Tasks::RemoteTask do

  let(:node) { Politburo::Resource::Node.new(name: "Node resource") }
  let(:task) { Politburo::Tasks::RemoteTask.new(node) }

  it "should initialize correctly" do
    task.should_not be_nil
    task.node.should be node
  end

  it { task.should be_a Politburo::Dependencies::Task }

end