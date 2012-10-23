require 'politburo'

describe Politburo::Resource::Node do

	let(:parent_resource) { Politburo::Resource::Base.new(name: "Parent resource") }
	let(:node) do 
		Politburo::Resource::Node.new(parent_resource: parent_resource, name: "Node resource")
	end

	it "should require a node_flavour" do
		node.node_flavour = nil
		node.should_not be_valid
	end

  context "#create_session" do
    it "should provide a connection to the node" do
      node.should_receive(:host).and_return(:host)
      node.should_receive(:user).and_return(:user)
      Net::SSH.should_receive(:start).with(:host, :user).and_return(:session)

      session = node.create_session

      session.should_not be_nil
      session.should be :session
    end
  end

end
