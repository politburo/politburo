require 'politburo'

describe Politburo::Resource::Base do

	let(:parent_resource) { Politburo::Resource::Base.new() }
	let(:resource) { Politburo::Resource::Base.new(parent_resource) }

	it "should initialize with parent" do
		resource.parent_resource.should == parent_resource
	end

end
