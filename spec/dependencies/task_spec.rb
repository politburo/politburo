describe Politburo::Dependencies::Task do 
  
  class TestTask
    include Politburo::Dependencies::Task
  end

  let(:task) { TestTask.new }

  it "should start in a unexecuted state" do
    task.should be_unexecuted
    task.state.should == :unexecuted
  end

  it "should raise an error if set in an unknown state" do
    lambda { task.state = :silly }.should raise_error "Unknown state: silly"
  end

  context "unsatisfied_idle_prerequisites" do
    let(:satisfied_task) { double("satisfied_task", :unsatisfied_and_idle? => false) }
    let(:unsatisfied_task_a) { double("unsatisfied_task_a", :unsatisfied_and_idle? => true) }
    let(:unsatisfied_task_b) { double("unsatisfied_task_b", :unsatisfied_and_idle? => true) }

    it "should return the subset of prerequisites which are unsatisfied" do
      task.prerequisites = [ satisfied_task, unsatisfied_task_a, unsatisfied_task_b ]

      task.unsatisfied_idle_prerequisites.should eq [ unsatisfied_task_a, unsatisfied_task_b ]
    end
  end

  context "#all_prerequisites_satisfied?" do
    let(:satisfied_task_a) { double("satisfied_task_a", :satisfied? => true) }
    let(:satisfied_task_b) { double("satisfied_task_b", :satisfied? => true) }
    let(:unsatisfied_task_a) { double("unsatisfied_task_a", :satisfied? => false) }
    let(:unsatisfied_task_b) { double("unsatisfied_task_b", :satisfied? => false) }

    it "should return false if there are unsatisfied tasks in the prerequisites" do
      task.prerequisites = [ satisfied_task_a, satisfied_task_b, unsatisfied_task_a, unsatisfied_task_b ]

      task.should_not be_all_prerequisites_satisfied
    end

    it "should return true if there are only satisfied tasks in the prerequisites" do
      task.prerequisites = [ satisfied_task_a, satisfied_task_b ]

      task.should be_all_prerequisites_satisfied
    end

    it "should return true if there no prerequisites (nil)" do
      task.prerequisites = nil
      task.should be_all_prerequisites_satisfied
    end

    it "should return true if there no prerequisites (empty)" do
      task.prerequisites = []
      task.should be_all_prerequisites_satisfied
    end

  end

  context "#done?" do

    before(:each) do
      task.stub(:satisfied?).and_return(true)
      task.stub(:all_prerequisites_satisfied?).and_return(true)
    end

    it "should return true iff all prerequisites satisfied and is satisfied" do
      task.should_receive(:satisfied?).and_return(true)
      task.should_receive(:all_prerequisites_satisfied?).and_return(true)

      task.should be_done
    end

    it "should return false if all prerequisites satisfied but is not satisfied" do
      task.should_receive(:satisfied?).and_return(false)

      task.should_not be_done
    end

    it "should return false if not all prerequisites satisfied even if is satisfied" do
      task.should_receive(:satisfied?).and_return(true)
      task.should_receive(:all_prerequisites_satisfied?).and_return(false)

      task.should_not be_done
    end

  end

  context "#unsatisfied_and_idle?" do

    it "should return false if satisfied" do
      task.state = :satisfied

      task.should_not be_unsatisfied_and_idle
    end

    it "should return false if executing" do
      task.state = :executing

      task.should_not be_unsatisfied_and_idle
    end

    it "should return true if ready to meet" do
      task.state = :ready_to_meet

      task.should be_unsatisfied_and_idle
    end

    it "should return true if unexecuted" do
      task.state = :unexecuted

      task.should be_unsatisfied_and_idle
    end

    it "should return true if failed" do
      task.state = :failed

      task.should be_unsatisfied_and_idle
    end
  end

  context "#fiber" do

    before :each do
      task.stub(:met?).and_return(false)
      task.stub(:all_prerequisites_satisfied?).and_return(true)
      task.fiber.should_not be_nil
    end

    it "should initially pause in unexecuted state" do
      task.should be_unexecuted
    end

    context "when checking if met" do

      it "should verify the task doesn't have unsatisfied prerequisites at this point" do
        task.should_receive(:all_prerequisites_satisfied?).and_return(true)
        task.fiber.resume
      end

      it "should fail if reached this point when task has unsatisfied prerequisites" do
        task.should_receive(:all_prerequisites_satisfied?).and_return(false)
        task.fiber.resume

        task.should be_failed
        task.cause_of_failure.message.should eq "Can't check if task was met when it has unsatisfied prerequisites"
      end

      it "should then check if it is met, if it isn't it should set state as ready to meet" do
        task.should_receive(:met?).and_return(false)
        task.fiber.resume
        task.should be_ready_to_meet
      end

      it "should check if it is met, if it is it should set state as met" do
        task.should_receive(:met?).and_return(true)
        task.fiber.resume
        task.should be_satisfied
      end

      it "should check if it is met, if met raises an error it should set the task as failed" do
        task.should_receive(:met?).and_raise "Whoops"
        task.fiber.resume
        task.should be_failed
        task.cause_of_failure.message.should eq "Whoops"
      end

    end

    context "when checked if met and is ready to execute" do

      before :each do
        task.fiber.resume
        task.should be_ready_to_meet
        task.stub(:meet).and_return(true)
        task.stub(:met?).and_return(true)
      end

      it "should verify the task doesn't have unsatisfied prerequisites at this point" do
        task.should_receive(:all_prerequisites_satisfied?).and_return(true)
        task.fiber.resume
      end

      it "should fail if reached this point when task has unsatisfied prerequisites" do
        task.should_receive(:all_prerequisites_satisfied?).and_return(false)
        task.fiber.resume

        task.should be_failed
        task.cause_of_failure.message.should eq "Can't execute task when it has unsatisfied prerequisites"
      end

       it "should attempt to meet, and be in executing state while meeting" do
        task.should_receive(:meet) do 
          task.should be_executing
          true
        end
        task.fiber.resume
        task.should be_satisfied
      end

      it "should attempt to meet, and if successful should be satisfied" do
        task.should_receive(:meet).and_return(true)
        task.fiber.resume
        task.should be_satisfied
      end

      it "should attempt to meet, and if it fails, it should be marked as failed" do
        task.should_receive(:meet).and_raise "Whoops"
        task.fiber.resume
        task.should be_failed
        task.cause_of_failure.message.should eq "Whoops"
      end

      it "should verify is met, and if it isn't, it should be marked as failed" do
        task.should_receive(:met?).and_return(false)
        task.fiber.resume
        task.should be_failed
      end
    end

  end
end