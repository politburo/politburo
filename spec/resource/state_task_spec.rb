describe Politburo::Resource::StateTask do

  let(:resource) { Politburo::Resource::Base.new(name: "Resource") }
  let(:state) { Politburo::Resource::State.new(resource: resource, name: "state") }
  let(:state_task) { Politburo::Resource::StateTask.new(parent_resource: state, prerequisites: [] ) }

  it "should initialize correctly" do
    state_task.resource_state.should be state
  end

  context "#resource" do

    it "should return the associated resource" do
      state_task.resource.should be resource
    end

  end
end