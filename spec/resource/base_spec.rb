require 'politburo'

describe Politburo::Resource::Base do

	let(:parent_resource) { Politburo::Resource::Base.new() }
	let(:resource) do 
		resource = Politburo::Resource::Base.new(parent_resource)

		resource.name = "Child resource"

		resource
	end

	it "should initialize with parent" do
		resource.parent_resource.should == parent_resource

		resource.should be_valid
	end

	it "should require a name" do
		resource.name = nil
		resource.should_not be_valid
	end

end
