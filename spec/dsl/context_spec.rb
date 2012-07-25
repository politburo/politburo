describe Politburo::DSL::Context do

	let(:root_definition) do
		Politburo::DSL.define do	

			environment(:name => "child environment", :environment_flavour => :amazon_web_services) do
				node(name: "node", node_flavour: "m1.large") {}
				node(name: "another node", node_flavour: "m1.large") {}
			end

		end
	end

	let(:node) { root_definition.find_all_by_attributes(name: "node").first }
	let(:another_node) { root_definition.find_all_by_attributes(name: "another node").first }
	
	context "::define" do

		it "should allow you to define a resource hierarchy" do
			root_definition.name.should eql("All")
			root_definition.children.should_not be_empty
			root_definition.children.length.should == 1
		end

	end

end