require 'politburo'

describe "End to end test" do

  let (:cli) { Politburo::CLI.create(arguments) }

	let(:arguments) { "-e #{environment_definition_file} #ready".split(/\s/) }

	describe "with simple environment" do

		let(:environment_definition_file) do
			File.join(File.dirname(__FILE__), "Simple.envfile.rb")
		end

		it "should run the envfile correctly", :skip => true do
			cli.run.should be_true
		end
	end

	describe "with complex environment" do

		let(:environment_definition_file) do
			File.join(File.dirname(__FILE__), "Complex.envfile.rb")
		end

		it "should run the envfile correctly", :skip => true do
			cli.run.should be_true
		end
	end

	describe "with Amazon environment" do

		let(:environment_definition_file) do
			File.join(File.dirname(__FILE__), "Amazon.envfile.rb")
		end

		let(:test_host) do
			cli.root.context.lookup(name: "Primary host in zone", availability_zone: :'ap-southeast-2')
		end

		it "should have an AWS cloud provider" do
			test_host.cloud_provider.should be_a Politburo::Resource::Cloud::AWSProvider
		end

		it "should run the envfile correctly" do
			test_host.should_not be_nil
			cli.run.should be_true
		end
	end

end