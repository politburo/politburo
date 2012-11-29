describe Politburo::Dependencies::Task do 
  
  class TestTask
    include Politburo::Dependencies::Task
  end

  let(:task) { 
    task = TestTask.new 
    task.logger.level = Logger::ERROR
    task.stub(:name).and_return('test-task')
    task
  }

  it "should start in a unexecuted state" do
    task.should be_unexecuted
    task.state.should == :unexecuted
  end

  it "should raise an error if set in an unknown state" do
    lambda { task.state = :silly }.should raise_error "Unknown state: silly"
  end

  context "unsatisfied_idle_prerequisites" do
    let(:satisfied_task) { double("satisfied_task", :available_for_queueing? => false) }
    let(:unsatisfied_task_a) { double("unsatisfied_task_a", :available_for_queueing? => true) }
    let(:unsatisfied_task_b) { double("unsatisfied_task_b", :available_for_queueing? => true) }

    it "should return the subset of prerequisites which are unsatisfied" do
      task.prerequisites = [ satisfied_task, unsatisfied_task_a, unsatisfied_task_b ]

      task.unsatisfied_idle_prerequisites.should eq [ unsatisfied_task_a, unsatisfied_task_b ]
    end
  end

  context "#paths" do
    before :each do
      task.paths << :path1
      task.paths << :path2
    end

    it "should maintain an ordered list of execution paths to the task" do
      task.paths.should eq [ :path1, :path2 ]
    end

    context "#primary_path" do
      it "should return the first path" do
        task.primary_path.should be :path1
      end

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

  context "#available_for_queueing?" do

    it "should return false if in progress" do
      task.should be_available_for_queueing

      task.in_progress = true

      task.should be_in_progress
      task.should_not be_available_for_queueing
    end

    it "should return false if satisfied" do
      task.state = :satisfied

      task.should_not be_available_for_queueing
    end

    it "should return false if it has been started" do
      task.state = :started

      task.should_not be_available_for_queueing
    end

    it "should return false if executing" do
      task.state = :executing

      task.should_not be_available_for_queueing
    end

    it "should return true if ready to meet" do
      task.state = :ready_to_meet

      task.should be_available_for_queueing
    end

    it "should return true if unexecuted" do
      task.state = :unexecuted

      task.should be_available_for_queueing
    end

    it "should return true if failed" do
      task.state = :failed

      task.should be_available_for_queueing
    end
  end

  context "#step" do

    before :each do
      task.stub(:met?).and_return(false)
      task.stub(:all_prerequisites_satisfied?).and_return(true)
      task.step
    end

    it "should initially pause in started state" do
      task.should be_started
    end

    it "should fail with an error if called when already satisfied" do
      task.state = :satisfied

      task.step

      task.should be_failed
      task.cause_of_failure.message.should eq "Assertion failed. Task resumed with .step() when already satisfied!"
    end

    it "should fail with an error if called when already failed" do
      task.state = :failed

      task.step

      task.should be_failed
      task.cause_of_failure.message.should eq "Assertion failed. Task resumed with .step() when already failed!"
    end

    context "when checking if met" do

      it "should verify the task doesn't have unsatisfied prerequisites at this point" do
        task.should_receive(:all_prerequisites_satisfied?).and_return(true)
        task.step
      end

      it "should fail if reached this point when task has unsatisfied prerequisites" do
        task.should_receive(:all_prerequisites_satisfied?).and_return(false)
        task.step

        task.should be_failed
        task.cause_of_failure.message.should eq "Can't check if task was met when it has unsatisfied prerequisites"
      end

      it "should then check if it is met, if it isn't it should set state as ready to meet" do
        task.should_receive(:met?).and_return(false)
        task.step
        task.should be_ready_to_meet
      end

      it "should check if it is met, if it is it should set state as met" do
        task.should_receive(:met?).and_return(true)
        task.step
        task.should be_satisfied
      end

      it "should check if it is met, if met raises an error it should set the task as failed" do
        task.should_receive(:met?).and_raise "Whoops"
        task.step
        task.should be_failed
        task.cause_of_failure.message.should eq "Whoops"
      end

    end

    context "when checked if met and is ready to execute" do

      before :each do
        task.step
        task.should be_ready_to_meet
        task.stub(:meet).and_return(true)
        task.stub(:met?).and_return(true)
      end

      it "should verify the task doesn't have unsatisfied prerequisites at this point" do
        task.should_receive(:all_prerequisites_satisfied?).and_return(true)
        task.step
      end

      it "should fail if reached this point when task has unsatisfied prerequisites" do
        task.should_receive(:all_prerequisites_satisfied?).and_return(false)
        task.step

        task.should be_failed
        task.cause_of_failure.message.should eq "Can't execute task when it has unsatisfied prerequisites"
      end

       it "should attempt to meet, and be in executing state while meeting" do
        task.should_receive(:meet) do 
          task.should be_executing
          true
        end
        task.step
        task.should be_satisfied
      end

      it "should attempt to meet, and if successful should be satisfied" do
        task.should_receive(:meet).and_return(true)
        task.step
        task.should be_satisfied
      end

      it "should attempt to meet, and if it fails with an error, it should be marked as failed" do
        task.should_receive(:meet).and_raise "Whoops"
        task.step
        task.should be_failed
        task.cause_of_failure.message.should eq "Whoops"
      end

      it "should attempt to meet, and if it fails with a nil or false return value, it should be marked as failed" do
        task.should_receive(:meet).and_return false
        task.step
        task.should be_failed
        task.cause_of_failure.message.should eq "Task 'test-task' failed as calling #meet() indicated failure by returning nil or false."
      end

      it "should verify is met, and if it isn't, it should be marked as failed" do
        task.should_receive(:met?).and_return(false)
        task.step
        task.should be_failed
        task.cause_of_failure.message.should eq "Task 'test-task' failed as its criteria hasn't been met after executing."
      end

      it "should call the task's cleanup method" do
        task.should_receive(:cleanup).and_return(true)
        task.step
      end

      it "should cleanup the task even if there was an error raised" do
        task.should_receive(:meet).and_raise "Whoops"
        task.should_receive(:cleanup).and_return(true)
        task.step
        task.should be_failed
        task.cause_of_failure.message.should eq "Whoops"
      end
      
    end

  end
end