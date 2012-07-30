require 'politburo'

describe Politburo::Resource::Base do

	let(:parent_resource) { Politburo::Resource::Base.new(name: "Parent resource") }
	let(:resource) do 
		Politburo::Resource::Base.new(parent_resource: parent_resource, name: "Child resource")
	end

	let(:sub_resource_1) do
		Politburo::Resource::Base.new(parent_resource: resource, name: "Sub Resource 1")
	end

	let(:sub_resource_2) do
		Politburo::Resource::Base.new(parent_resource: resource, name: "Sub Resource 2")
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

	context "states" do

		it "should have minimum default states with their dependencies" do
			resource.states.should_not be_empty
			resource.state(:ready).should be_dependent_on resource.state(:configured) 
			resource.state(:configured).should be_dependent_on resource.state(:configuring)
		end

		context "#add_dependency_on" do
			
			it "should delegate to ready state's add_dependency_on with the target" do
				resource.state(:ready).should_receive(:add_dependency_on).with( sub_resource_1.state(:configured) )
				resource.add_dependency_on(sub_resource_1.state(:configured))
			end
		end

	end

	context "searchable" do

		it "should be ::Searchable" do
			resource.should be_a Politburo::Resource::Searchable
		end

		context "#contained_searchables" do
			before :each do
				sub_resource_1.should_not be_nil
				sub_resource_2.should_not be_nil
				resource.children.should_not be_empty
			end

			it "should include both child resources and state resources" do
				resource.contained_searchables.length.should == 8
			end

			it "should include all child resources" do
				resource.contained_searchables.should include(sub_resource_1)
				resource.contained_searchables.should include(sub_resource_2)
			end

			it "should include all states resources" do
				resource.contained_searchables.should include(resource.state(:ready))

				resource.states.each do | state | 
					resource.contained_searchables.should include(state)
				end
			end
		end
	end

	context "#generate_babushka_deps" do

		let(:io) { StringIO.new() }

		it "should generate the deps for each state" do
			resource.states.each { | state | state.should_receive(:generate_babushka_deps).with(io).exactly(1).times }

			resource.generate_babushka_deps(io)
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
