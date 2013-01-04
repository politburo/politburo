require 'politburo'

describe Politburo::DSL::Context do

	let(:root_definition) do
		Politburo::DSL.define do

			environment(name: "environment", provider: :aws) do
				node(name: "node", provider: "m1.large") {}
				node(name: "another node", provider: "m1.large") do
					depends_on node(name: "node") { self.description= "node description" }.state(:configured)
				end
				node(name: "yet another node", provider: "m1.large") do
					state(:configured) do
						depends_on node("node")

						remote_task(
        			name: 'install babushka',
        			command: 'sudo sh -c "`curl https://babushka.me/up`"', 
        			met_test_command: 'which babushka') {	}
					end
				end
			end

			environment(name: 'another environment', provider: :aws) do
				node(name: "a node from another galaxy", provider: "c1.xlarge") {}
			end
		end
	end

	let(:environment) { root_definition.find_all_by_attributes(name: 'environment').first }
	let(:another_environment) { root_definition.find_all_by_attributes(name: 'another environment').first }

	let(:node) { root_definition.find_all_by_attributes(name: :node).first }
	let(:another_node) { root_definition.find_all_by_attributes(name: "another node").first }
	let(:yet_another_node) { root_definition.find_all_by_attributes(name: "yet another node").first }

	let(:remote_task) { root_definition.find_all_by_attributes(name: "install babushka").first }

	let(:another_environment_node) { another_environment.find_all_by_attributes(:class => Politburo::Resource::Node).first }
	
	context "::define" do
		context "unit test" do

			let (:root) { double("root resource") }
			let (:context) { double("root context") }

			before :each do
				Politburo::Resource::Root.stub(:new).with(name: "").and_return(root)
				root.stub(:context).and_return(context)
				context.stub(:define).with("string eval").and_return(root)
				context.stub(:validate!)
			end

			it "should create a new root resource" do
				Politburo::Resource::Root.should_receive(:new).with(name: "").and_return(root)

				Politburo::DSL.define("string eval") { "a block" }
			end

			it "should create a new root context" do
				root.should_receive(:context).and_return(context)

				Politburo::DSL.define("string eval") { "a block" }
			end

			it "should call define on the root context" do
				context.should_receive(:define).with("string eval").and_return(root)

				Politburo::DSL.define("string eval") { "a block" }
			end

			it "should call validate on the root context" do
				context.should_receive(:validate!)

				Politburo::DSL.define("string eval") { "a block" }
			end

		end

		context "effects test" do
			it "should allow you to define a resource hierarchy" do
				root_definition.name.should eql("")
				root_definition.children.should_not be_empty
				root_definition.children.length.should == 2
			end

			it "defined hierarchy, should define an implicit state dependency" do
				environment.state(:ready).should be_dependent_on node.state(:ready)
				environment.state(:ready).should be_dependent_on another_node.state(:ready)
			end

			it "should allow you to define state dependencies" do
				another_node.state(:ready).should be_dependent_on node.state(:configured)
				yet_another_node.state(:configured).should be_dependent_on node.state(:ready)
			end

			it "should allow you to define execution tasks for states" do
				remote_task.should_not be_nil
				yet_another_node.state(:configured).should be_dependent_on remote_task
			end

			it "should allow to modify the resource while finding it" do
				node.description.should eq "node description"
			end
		end

	end

	context "instance" do
		let(:receiver) { double("receiver") }
		let(:context) { Politburo::DSL::Context.new(receiver) }

		context "#define" do

				it "should wrap internal errors in a context exception" do
					lambda { context.define { raise "Internal error" } }.should raise_error /.*Internal error.*/
				end

		end

		context "#validate!" do
			let(:fake_resource_a) { double("fake resource a") }
			let(:fake_resource_b) { double("fake resource b") }

	    it "should iterate all resources (depth first) starting with the receiver and call #validate! on each" do
	      receiver.should_receive(:each).and_yield(fake_resource_a).and_yield(fake_resource_b)
	      fake_resource_a.should_receive(:validate!)
	      fake_resource_b.should_receive(:validate!)

	      context.send(:validate!)
	    end

		end

		context "#lookup" do

			let(:context_for_environment) { environment.context }
			let(:context_for_node) { node.context }

			it "should use find_one_by_attributes" do
				context_for_node.should_receive(:find_one_by_attributes).with(class: Politburo::Resource::Node).and_return(context_for_node)
				context_for_node.lookup(class: Politburo::Resource::Node).receiver.should be node
			end

			it "should lookup in parent's hierarchy next" do
				context_for_node.lookup(name: 'another node').receiver.should == another_node
			end

			it "should travel up to the root if neccessary" do
				context_for_node.lookup(name: 'a node from another galaxy').receiver.should == another_environment_node
			end

			it "should raise error if found none" do
				lambda { context_for_environment.lookup(name: 'Does not exist') }.should raise_error('Could not find receiver by attributes: {:name=>"Does not exist"}.')
			end

		end

		context "#find_one_by_attributes" do

			let(:context_for_environment) { environment.context }
			let(:context_for_node) { node.context }

			it "should lookup first within a resource hierarchy" do
				context_for_node.find_one_by_attributes(class: Politburo::Resource::Node).receiver.should be node
			end

			it "should lookup in parent's hierarchy next" do
				context_for_node.find_one_by_attributes(name: 'another node').receiver.should be another_node
			end

			it "should travel up to the root if neccessary" do
				context_for_node.find_one_by_attributes(name: 'a node from another galaxy').receiver.should be another_environment_node
			end

			it "should raise error if found more than one" do
				lambda { context_for_environment.find_one_by_attributes(class: Politburo::Resource::Node) }.should raise_error("Ambiguous receiver for attributes: {:class=>Politburo::Resource::Node}. Found: \"node\", \"another node\", \"yet another node\".")
			end


			it "should return nil if found none" do
				context_for_environment.find_one_by_attributes(name: 'Does not exist').should be nil
			end			
		end

		context "#find_or_create_resource" do
			let(:context) { node.context }

			before :each do
				context.stub(:find_and_define_resource).with(:class, :attributes)
			end

			it "should attempt to find an existing receiver" do
				context.should_receive(:find_and_define_resource).with(:class, :attributes).and_return(:existing_receiver)

				context.find_or_create_resource(:class, :attributes) {}
			end

			context "when an existing receiver doesn't exist" do

				it "should attempt to create a new one" do
					context.should_receive(:find_and_define_resource).with(:class, :attributes).and_return(nil)
					context.should_receive(:create_and_define_resource).with(:class, :attributes).and_return(:new_receiver)
					context.find_or_create_resource(:class, :attributes).should be :new_receiver
				end

			end
		end

		context "#create_and_define_resource" do
			let(:context) { node.context }
			let(:new_receiver) { double("new receiver") }
			let(:new_receiver_context) { double("new receiver context", receiver: new_receiver) }

			before :each do
				context.stub(:create_receiver).with(:class, :attributes).and_return(new_receiver_context)
				new_receiver_context.stub(:define).and_yield
				node.stub(:add_dependency_on).with(new_receiver)
			end

			it "should create a new receiver" do
				context.should_receive(:create_receiver).with(:class, :attributes).and_return(new_receiver_context)

				(context.create_and_define_resource(:class, :attributes) {}).should be new_receiver_context
			end

			it "should raise an error if no block was given" do
				lambda {context.create_and_define_resource(:class, :attributes).should be new_receiver }.should raise_error "No block given for defining a new receiver."
			end

			it "should call define on the context" do
				new_receiver_context.should_receive(:define).and_yield

				(context.create_and_define_resource(:class, :attributes) { }).should be new_receiver_context
			end

			it "should add a dependency on the new receiver" do
				node.should_receive(:add_dependency_on).with(new_receiver)

				(context.create_and_define_resource(:class, :attributes) {}).should be new_receiver_context
			end
		end

		context "#find_and_define_resource" do
			let(:context) { node.context }
			let(:existing_resource) { double("existing resource") }
			let(:existing_resource_context) { double("existing resource context", receiver: existing_resource) }

			before :each do
				context.stub(:find_attributes).with(:class, :attributes).and_return(:find_attrs)
				context.stub(:find_one_by_attributes).with(:find_attrs).and_return(nil)
			end

			it "should use find_attributes to construct the attributes to use for finding the resource" do
				context.should_receive(:find_attributes).with(:class, :attributes).and_return(:find_attrs)

				context.find_and_define_resource(:class, :attributes).should be nil
			end

			it "should attempt to find resource by attributes" do
				context.should_receive(:find_one_by_attributes).with(:find_attrs).and_return(nil)

				context.find_and_define_resource(:class, :attributes).should be nil
			end

			context "when resource is found" do
				before :each do
					context.stub(:find_one_by_attributes).with(:find_attrs).and_return(existing_resource_context)
				end

				it "should call define on its context" do
					existing_resource_context.should_receive(:define).and_yield

					context.find_and_define_resource(:class, :attributes) {} .should be existing_resource_context
				end
			end

		end

		context "#method_missing" do

			it "should delegate to the underlying receiver with all arguments" do
				receiver.should_receive(:some_method_that_doesnt_exit).with(:param_a, :param_b)

				context.define { some_method_that_doesnt_exit(:param_a, :param_b) }
			end

			it "should delegate to the underlying receiver with all arguments" do
				receiver.should_receive(:description=).with(:value)

				context.description= :value
			end

		end
	end
end