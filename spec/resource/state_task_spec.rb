describe Politburo::Resource::StateTask do

  let(:resource) { Politburo::Resource::Base.new(name: "Resource") }
  let(:state) { Politburo::Resource::State.new(parent_resource: resource, name: "state") }
  let(:state_task) { Politburo::Resource::StateTask.new(parent_resource: state ) }

  it "should initialize correctly" do
    state_task.resource_state.should be state
  end

  context "#resource" do

    it "should return the associated resource" do
      state_task.resource.should be resource
    end

  end

  context "#prerequisites" do
    let(:state_dependency) { double("state dependency") }
    let(:task_dependency) { double("task dependency") }
    let(:state_dependencies) { double("state dependencies") }
    let(:task_dependencies) { double("state task dependencies") }
    let(:state_dependencies_as_tasks) { double("state dependencies as tasks") }
    let(:task_dependencies_as_tasks) { double("state task dependencies as tasks") }
    let(:combined_tasks) { double("state & state task dependencies as tasks") }

    it "should include the associated state's state dependencies (as tasks) and combine with own dependencies as prerequisites" do
      state_task.prerequisites.should_not be_nil
      state.should_receive(:state_dependencies).and_return(state_dependencies)
      state_task.should_receive(:dependencies).and_return(task_dependencies)

      state_dependency.should_receive(:to_task).and_return(:state_dependency_as_task)
      task_dependency.should_receive(:to_task).and_return(:task_dependency_as_task)

      state_dependencies.should_receive(:map).and_yield(state_dependency).and_return(state_dependencies_as_tasks)
      task_dependencies.should_receive(:map).and_yield(task_dependency).and_return(task_dependencies_as_tasks)

      state_dependencies_as_tasks.should_receive(:+).with(task_dependencies_as_tasks).and_return(combined_tasks)

      Set.should_receive(:new).with(combined_tasks).and_return(:resulting_set)

      state_task.prerequisites.should be :resulting_set
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

  context "logging" do
    it "should have a log" do
      resource.should be_a Politburo::Support::HasLogger
    end

    it "should have a different default log formatter" do
      resource.log_formatter.call(Logger::ERROR, Time.now, "my prog", "error message").should include resource.full_name
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