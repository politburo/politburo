describe Politburo::DSL::Context do

	let(:root_definition) do
		Politburo::DSL.define do	

			environment(:name => "child environment", :environment_flavour => :amazon_web_services) do
				node(name: "node", node_flavour: "m1.large") {}
				node(name: "another node", node_flavour: "m1.large") do
					depends_on node(name: "node").state(:configured)
				end
				node(name: "yet another node", node_flavour: "m1.large") do
					state('configured').depends_on node(name: "node")
				end
			end

		end
	end

	let(:environment) { root_definition.find_all_by_attributes(name: 'child environment').first }
	let(:node) { root_definition.find_all_by_attributes(name: :node).first }
	let(:another_node) { root_definition.find_all_by_attributes(name: "another node").first }
	let(:yet_another_node) { root_definition.find_all_by_attributes(name: "yet another node").first }
	
	context "::define" do

		it "should allow you to define a resource hierarchy" do
			root_definition.name.should eql("All")
			root_definition.children.should_not be_empty
			root_definition.children.length.should == 1
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

	end

end