require 'politburo'

describe Politburo::Resource::Node do

	let(:parent_resource) { Politburo::Resource::Base.new() }
	let(:node) do 
		node = Politburo::Resource::Node.new(parent_resource)

		node.name = "Node resource"

		node
	end

	it "should require a node_flavour" do
		node.node_flavour = nil
		node.should_not be_valid
	end

end
