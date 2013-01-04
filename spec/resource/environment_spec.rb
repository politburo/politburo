require 'politburo'

describe Politburo::Resource::Environment do

	let(:parent_resource) { Politburo::Resource::Base.new(name: 'Parent resource') }
	let(:environment) { Politburo::Resource::Environment.new(parent_resource: parent_resource, name: "Environment resource") }

  it("should have its own context class") { environment.context_class.should be Politburo::Resource::EnvironmentContext }

	it "should require an provider" do
		environment.provider = nil
		environment.should_not be_valid
	end

	it "should allow a region" do
		environment.region = :us_west_1
		environment.region.should be :us_west_1
	end

	it "should allow a provider configuration parameter" do
		environment.provider_config = {}
		environment.provider_config.should be {}
	end

	it "should have all the default states" do
		parent_resource.states.each do | state | 
			state = environment.state(state.name)
			state.should_not be_nil
		end
	end
end
