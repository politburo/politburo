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

  context "#cleanup" do
    let(:stdout_console) { double("stdout console") }
    let(:stderr_console) { double("stderr console") }

    before :each do
      state_task.instance_variable_set(:@stdout_console, stdout_console)
      state_task.instance_variable_set(:@stderr_console, stderr_console)

      state_task.stub(:stdout_console).and_return(stdout_console)
      state_task.stub(:stderr_console).and_return(stderr_console)

      stdout_console.stub(:close)
      stderr_console.stub(:close)
    end

    it "should call close on stdout console" do
      state_task.should_receive(:stdout_console).and_return(stdout_console)
      stdout_console.should_receive(:close)

      state_task.cleanup
    end

    it "should call close on stderr console" do
      state_task.should_receive(:stderr_console).and_return(stderr_console)
      stderr_console.should_receive(:close)

      state_task.cleanup
    end

    it "should return true" do
      state_task.cleanup.should be_true
    end
  end

  context "#stdout_console" do
    let (:console) { double("fake console") }

    it "should return a console with a prefix" do
      state_task.should_receive(:stdout_console_prefix).and_return("console_prefix")
      Politburo::Support::Consoles.instance.should_receive(:create_console).and_return(console)

      state_task.stdout_console.should == console
    end
  end

  context "#stderr_console" do
    let (:console) { double("fake console") }

    it "should return a console with a prefix" do
      state_task.should_receive(:stderr_console_prefix).and_return("console_prefix")
      Politburo::Support::Consoles.instance.should_receive(:create_console).and_return(console)

      state_task.stderr_console.should == console
    end
  end

end