require 'politburo'

describe Politburo::DSL::Context do

	let(:root_definition) do
		Politburo::DSL.define do

			environment(name: "environment", provider: :aws) do
				node(name: "node", provider: "m1.large") {}
				node(name: "another node", provider: "m1.large") do
					depends_on node(name: "node").state(:configured)
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
				Politburo::Resource::Base.stub(:new).with(name: "").and_return(root)
				root.stub(:context).and_return(context)
				context.stub(:define).with("string eval").and_return(root)
				context.stub(:validate!)
			end

			it "should create a new root resource" do
				Politburo::Resource::Base.should_receive(:new).with(name: "").and_return(root)

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

			let(:context_for_environment) { Politburo::DSL::Context.new(environment) }
			let(:context_for_node) { Politburo::DSL::Context.new(node) }

			it "should lookup first within a resource hierarchy" do
				context_for_node.lookup(:class => Politburo::Resource::Node).receiver.should == node
			end

			it "should lookup in parent's hierarchy next" do
				context_for_node.lookup(name: 'another node').receiver.should == another_node
			end

			it "should travel up to the root if neccessary" do
				context_for_node.lookup(name: 'a node from another galaxy').receiver.should == another_environment_node
			end

		end
	end
end