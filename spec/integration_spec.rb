require 'politburo'

describe "Integration" do

	let(:target_dir_path) { File.join(File.dirname(__FILE__), "..", "tmp", Time.now.to_i.to_s) }

	let(:simple_environment_definition) do
		Politburo::DSL.define do

			environment(name: "child environment", environment_flavour: :amazon_web_services) do
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

	let(:complex_environment_definition) do
		Politburo::DSL.define do

			environment(name: "Complex Test Environment", environment_flavour: :amazon_web_services) do

				# This defines the database master + slaves
				facet(name: "Database", cardinality: 1) do
					database_master(name: "Database Master", node_flavour: "c1.xlarge", database_flavour: "postgres") do
					end
					facet(name: "Database Slaves", cardinality: 2) do
						database_slave(name: "Database Slave", node_flavour: "m1.large", database_flavour: "postgres") do
							depends_on database_master(name: "Database Master").state(:ready)
						end
					end
				end

				# This defines the load-balancer + webserver nodes
				facet(name: "Webnodes") do
					depends_on facet(name: "Database")
					webnode(name: "Load Balancer", node_flavour: "c1.xlarge") do
						# At the very least, the IP addresses for the slaves would be required to configure the load balancer
						state(:ready_to_configure).depends_on facet(name: "Webnode Instances").state(:running) 
					end
					facet(name: "Webnode Instances", cardinality: 2) do
						webnode(name: "Webnode", node_flavour: "m1.large") do
						end
					end 
				end

			end

		end
	end

	before(:each) do
		FileUtils.mkdir_p(target_dir_path)
	end

	describe "end-to-end process" do

		before :each do
		end

		it "should have generated the babushka deps into the target directory" do
			fail("todo")
		end

	end
end