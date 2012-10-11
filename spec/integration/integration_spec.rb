require 'politburo'

describe "Integration" do

  let (:cli) { Politburo::CLI.create(arguments) }

	let(:simple_environment_definition_file) do
		File.join(File.dirname(__FILE__), "Simple.envfile.rb")
	end

	let(:complex_environment_definition) do
		File.join(File.dirname(__FILE__), "Complex.envfile.rb")
	end

	describe "end-to-end process" do

		describe "simple environment" do
			let(:arguments) { "-e #{simple_environment_definition_file} simple".split(/\s/) }

			it "should run the simple envfile correctly" do
				cli.run
			end
		end

	end
end