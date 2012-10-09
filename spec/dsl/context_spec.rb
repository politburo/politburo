require 'politburo'

describe Politburo::DSL::Context do

	let(:root_definition) do
		Politburo::DSL.define do	

			environment(name: "environment", environment_flavour: :amazon_web_services) do
				node(name: "node", node_flavour: "m1.large") {}
				node(name: "another node", node_flavour: "m1.large") do
					depends_on node(name: "node").state(:configured)
				end
				node(name: "yet another node", node_flavour: "m1.large") do
					state('configured').depends_on node(name: "node")
				end
			end

			environment(name: 'another environment', environment_flavour: :amazon_web_services) do
				node(name: "a node from another galaxy", node_flavour: "c1.xlarge") {}
			end
		end
	end

	let(:environment) { root_definition.find_all_by_attributes(name: 'environment').first }
	let(:another_environment) { root_definition.find_all_by_attributes(name: 'another environment').first }

	let(:node) { root_definition.find_all_by_attributes(name: :node).first }
	let(:another_node) { root_definition.find_all_by_attributes(name: "another node").first }
	let(:yet_another_node) { root_definition.find_all_by_attributes(name: "yet another node").first }

	let(:another_environment_node) { another_environment.find_all_by_attributes(:class => Politburo::Resource::Node).first }
	
	context "::define" do

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
	end

	context "#lookup" do

		let(:context_for_environment) { Politburo::DSL::Context.new(environment) }
		let(:context_for_node) { Politburo::DSL::Context.new(node) }

		it "should lookup first within a resource hierarchy" do
			context_for_node.lookup(:class => Politburo::Resource::Node).should == node
		end

		it "should lookup in parent's hierarchy next" do
			context_for_node.lookup(name: 'another node').should == another_node
		end

		it "should travel up to the root if neccessary" do
			context_for_node.lookup(name: 'a node from another galaxy').should == another_environment_node
		end

	end

end