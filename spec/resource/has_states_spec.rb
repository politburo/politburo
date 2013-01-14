describe Politburo::Resource::HasStates do

	let(:has_state_class) do
		Class.new do
			include Politburo::DSL::DslDefined
			include Politburo::Resource::HasStates
			include Politburo::Resource::HasDependencies

			def initialize(attributes)
				update_attributes(attributes)
			end

			attr_accessor :full_name
		end
	end

	let(:state_obj) do
		has_state_class.new(full_name: 'state object')
	end

	it { state_obj.should be_a Politburo::DSL::DslDefined }

	it "should have implied defined" do
		has_state_class.should respond_to(:implies)
	end

	let(:ready_state) do
		Politburo::Resource::State.new(name: 'ready')
	end

	let(:steady_state) do
		steady = Politburo::Resource::State.new(name: :steady)
		steady.add_dependency_on(ready_state)
		steady
	end

	before :each do
		state_obj.add_child(ready_state)
		state_obj.add_child(steady_state)
	end

	context "#states" do
		it "should return direct descendant states that match the specified attributes" do
			state_obj.states(name: 'ready').should include ready_state
		end
	end

	it "should maintain a list of states it can be in" do
		state_obj.children.should_not be_empty
		state_obj.children.should include(ready_state)
		state_obj.children.should include(steady_state)

		state_obj.contained_searchables.should be state_obj.children

		state_obj.states.should_not be_empty
	end

	context "#state" do

		it "should look up states by their name" do
			state_obj.state(:ready).should == ready_state
			state_obj.state(:steady).should == steady_state
		end

	end

	context "::has_state" do

		let(:defined_state_class) do
			Class.new(has_state_class) do
				has_state :set
				has_state :go => :set
				has_state :ready => [ :set ]
				has_state :ready => [ :set, :go ]
			end
		end

		it "should have implied defined" do
			defined_state_class.should respond_to(:implies)
		end

		let (:defined_state_obj) { 
			_class = defined_state_class
			Politburo::DSL.define() {
				lookup_or_create_resource(_class, full_name: 'has defined state') {}
			}.children.first
		}

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