require 'politburo'

describe Politburo::Resource::Environment do

	let(:parent_resource) { Politburo::Resource::Base.new(name: 'Parent resource') }
	let(:environment) { Politburo::Resource::Environment.new(name: "Environment resource") }

  before :each do
    parent_resource.add_child(environment)
  end

	it "should have all the default states" do
		parent_resource.states.each do | state | 
			state = environment.state(state.name)
			state.should_not be_nil
		end
	end
end
