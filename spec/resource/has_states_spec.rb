describe Politburo::Resource::HasStates do

	class StateObj 
		include Politburo::DSL::DslDefined
		include Politburo::Resource::HasStates

		def full_name
			"state obj"
		end

		def contained_searchables
			states
		end
	end

	let(:state_obj) do
		StateObj.new()
	end

	let(:ready_state) do
		Politburo::Resource::State.new(name: 'ready', parent_resource: state_obj)
	end

	let(:steady_state) do
		steady = Politburo::Resource::State.new(name: :steady, parent_resource: state_obj)

		steady.dependencies << ready_state

		steady
	end

	before :each do
		state_obj.states << ready_state
		state_obj.states << steady_state
	end

	context "#find_states" do
		it "should return direct descendant states that match the specified attributes" do
			state_obj.find_states(name: 'ready').should include ready_state
		end
	end

	it "should maintain a list of states it can be in" do
		state_obj.states.should_not be_empty
	end

	context "#state" do

		it "should look up states by their name" do
			state_obj.state(:ready).should == ready_state
			state_obj.state(:steady).should == steady_state
		end

	end

	context "#define_state" do

		context "with just a state name" do
			before :each do
				state_obj.define_state :set
			end

			it "should add the state correctly" do

				state_obj.state(:set).should_not be_nil
			end
		end

		context "with a state name and one dependency" do
			before :each do
				state_obj.define_state :set
				state_obj.define_state :go => :set
			end

			it "should add the state correctly" do
				state_obj.state(:go).should_not be_nil
			end

			it "should add the state depenency correctly" do
				state_obj.state(:go).should be_dependent_on state_obj.state(:set)
			end
		end

		context "with a state name and multiple dependencies" do
			before :each do
				state_obj.define_state :set
				state_obj.define_state :go
				state_obj.define_state :very_ready => [ :set, :go ]
			end

			it "should add the state correctly" do
				state_obj.state(:very_ready).should_not be_nil
			end

			it "should add the state depenencies correctly" do
				state_obj.state(:very_ready).should be_dependent_on state_obj.state(:set)
				state_obj.state(:very_ready).should be_dependent_on state_obj.state(:go)
			end
		end

		context "with an existing state name and multiple dependencies" do
			before :each do
				state_obj.define_state :set
				state_obj.define_state :go
				state_obj.define_state :ready => [ :set, :go ]
			end

			it "should add the state correctly" do
				state_obj.state(:ready).should_not be_nil
			end

			it "should add the state depenencies correctly" do
				state_obj.state(:ready).should be_dependent_on state_obj.state(:set)
				state_obj.state(:ready).should be_dependent_on state_obj.state(:go)
			end
		end

		context "with multiple key values" do

			it "should raise an error" do

				lambda { state_obj.define_state(:ready => :or_not, :here => :we_come) }.should raise_error("Must have one, and only one key->value pair in state definition")
			end

		end

	end

	context "::has_state" do
		class DefinedStateObj < StateObj
			has_state :set
			has_state :go => :set
			has_state :ready => [ :set, :go ]
		end

		let (:defined_state_obj) { DefinedStateObj.new() }

		it "should add a state to be added on initialization" do
			defined_state_obj.state(:set).should_not be_nil
		end

		it "should add a state with a dependency on initialization" do
			defined_state_obj.state(:go).should_not be_nil
			defined_state_obj.state(:go).should be_dependent_on defined_state_obj.state(:set)
		end

		it "should add a state with multiple dependencies on initialization" do
			defined_state_obj.state(:ready).should_not be_nil
			defined_state_obj.state(:ready).should be_dependent_on defined_state_obj.state(:set)
			defined_state_obj.state(:ready).should be_dependent_on defined_state_obj.state(:go)
		end
	end
end