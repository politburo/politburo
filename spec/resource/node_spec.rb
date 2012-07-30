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

end
