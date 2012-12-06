require 'politburo'

describe "End to end test" do

  let (:cli) { Politburo::CLI.create(arguments) }

	let(:complex_environment_definition) do
		File.join(File.dirname(__FILE__), "Complex.envfile.rb")
	end

	let(:arguments) { "-e #{environment_definition_file} #ready".split(/\s/) }

	describe "with simple environment" do

		let(:environment_definition_file) do
			File.join(File.dirname(__FILE__), "Simple.envfile.rb")
		end

		it "should run the envfile correctly" do
			cli.run.should be_true
		end
	end

	describe "with Amazon environment" do

		let(:environment_definition_file) do
			File.join(File.dirname(__FILE__), "Amazon.envfile.rb")
		end

		it "should run the envfile correctly" do
			cli.run.should be_true
		end
	end

end