describe Politburo::Tasks::StartTask do

  let(:node) { Politburo::Resource::Node.new(name: "Node resource") }
  let(:state) { node.state(:started) }
  let(:task) { Politburo::Tasks::StartTask.new(name: 'Start', resource_state: state) }

  it "should check if the node has started" do
  end

end
