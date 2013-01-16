require 'politburo'

describe "End to end test" do

  let (:cli) { Politburo::CLI.create(arguments) }

	let(:arguments) { [
		"-e", environment_definition_file, 
		"#{target}##{state_to_achieve}",
		"--private-keys-dir", (Pathname.new(environment_definition_file).parent + ".ssh").to_s
		] }

	describe "with Amazon environment" do
		let(:environment_definition_file) do
			File.join(File.dirname(__FILE__), "Amazon.envfile.rb")
		end

  	let(:target) { "Amazon:APAC South East 2 (Sydney)" }

		let(:test_host) do
			cli.root.context.lookup(name: "Primary host in zone", region: 'ap-southeast-2')
		end

  	let(:security_group) do
  		cli.root.context.lookup(class: Politburo::Plugins::Cloud::SecurityGroup, parent_resource: test_host.parent_resource)
  	end

		let(:number_of_hosts) { 8 }

		let(:run) { cli.run }

		before(:each) do
			run.should be_true
			test_host.should_not be_nil
			test_host.cloud_provider.should be_a Politburo::Plugins::Cloud::AWSProvider
		end

		context "#defined" do
			let(:state_to_achieve) { "defined" }

			let(:nodes) { cli.root.find_all_by_attributes(class: /Node/) }
			let(:security_groups) { cli.root.find_all_by_attributes(class: Politburo::Plugins::Cloud::SecurityGroup) }

			it "define the elements correctly" do
				nodes.size.should be number_of_hosts

				security_groups.size.should be number_of_hosts
				security_groups.each do | security_group |
					security_group.parent_resource.should be_a Politburo::Resource::Facet
				end
			end
		end

		context "#ready", :end_to_end => true do
			let(:state_to_achieve) { "ready" }

			it "should start the cloud server correctly and set up the security group for it" do
				test_host.cloud_server.state.should == "running"
				security_group.cloud_security_group.should_not be_nil
			end
		end

		context "#terminated", :end_to_end => true do
			let(:state_to_achieve) { "terminated" }

			it "should terminate the cloud server correctly" do
				test_host.cloud_server.state.should == "terminated"
			end
		end

	end
end