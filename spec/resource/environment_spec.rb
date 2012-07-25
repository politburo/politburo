require 'politburo'

describe Politburo::Resource::Environment do

	let(:parent_resource) { Politburo::Resource::Base.new() }
	let(:environment) do 
		environment = Politburo::Resource::Environment.new(parent_resource)

		environment.name = "Environment resource"

		environment
	end

	it "should require an environment_flavour" do
		environment.environment_flavour = nil
		environment.should_not be_valid
	end

end
