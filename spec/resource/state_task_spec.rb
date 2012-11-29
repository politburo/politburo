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

  context "#as_dependency" do
    it "should return itself" do
      state_task.as_dependency.should be state_task
    end
  end

  context "#to_task" do
    it "should return itself" do
      state_task.to_task.should be state_task
    end
  end

  context "#parent_resource" do
    it "should return the resource state this task is part of" do
      state_task.parent_resource.should be state
    end
  end

  context "#stdout_console" do
    let (:console) { double("fake console") }

    it "should return a console" do
      Politburo::Support::Consoles.instance.should_receive(:create_console).and_return(console)

      state_task.stdout_console.should == console
    end
  end

  context "#stderr_console" do
    let (:console) { double("fake console") }

    it "should return a console" do
      Politburo::Support::Consoles.instance.should_receive(:create_console).and_return(console)

      state_task.stderr_console.should == console
    end
  end

end