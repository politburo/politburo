require 'politburo'

describe Politburo::Resource::Base do

	let(:parent_resource) { Politburo::Resource::Base.new() }
	let(:resource) do 
		resource = Politburo::Resource::Base.new(parent_resource)

		resource.name = "Child resource"

		resource
	end

	let(:sub_resource_1) do
		sub_resource = Politburo::Resource::Base.new(resource)
		sub_resource.name = "Sub Resource 1"
		sub_resource
	end

	let(:sub_resource_2) do
		sub_resource = Politburo::Resource::Base.new(resource)
		sub_resource.name = "Sub Resource 2"
		sub_resource
	end

	it "should initialize with parent" do
		resource.parent_resource.should == parent_resource

		resource.should be_valid
	end

	it "should require a name" do
		resource.name = nil
		resource.should_not be_valid
	end

	it "should be searchable" do
		resource.should be_a Politburo::Resource::Searchable
	end

	context "#children" do

		it "should maintain a list of children" do
			parent_resource.children.should be_empty

			resource.should_not be_nil

			parent_resource.children.should_not be_empty
			parent_resource.children.length.should == 1
			parent_resource.children.first.should == resource

			resource.children.should be_empty

			sub_resource_1.should_not be_nil
			sub_resource_2.should_not be_nil

			resource.children.should_not be_empty
			resource.children.length.should == 2
			resource.children.should include(sub_resource_1)
			resource.children.should include(sub_resource_2)
		end
	end

	context "#root" do

		it "should return the root resource" do
			sub_resource_1.root.should == parent_resource
			sub_resource_2.root.should == parent_resource
			resource.root.should == parent_resource
			parent_resource.root.should == parent_resource
		end
	end

end
