require 'politburo'

describe Politburo::Resource::Environment do

	let(:parent_resource) { Politburo::Resource::Base.new(name: 'Parent resource') }
	let(:environment) { Politburo::Resource::Environment.new(parent_resource: parent_resource, name: "Environment resource") }

	it "should require an environment_flavour" do
		environment.environment_flavour = nil
		environment.should_not be_valid
	end

	it "should have all the default states" do
		parent_resource.states.each do | state | 
			state = environment.state(state.name)
			state.should_not be_nil
		end
	end
end
