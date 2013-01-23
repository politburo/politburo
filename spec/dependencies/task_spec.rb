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

  context "logging" do
    it "should have a log" do
      task.should be_a Politburo::Support::HasLogger
    end

    it "should have a different default log formatter" do
      task.log_formatter.call(Logger::ERROR, Time.now, "my prog", "error message").should include task.name
    end

    
    it "should colorize the severity of the log message" do
      task.log_formatter.call(:error, Time.now, "Test prog", "Message").should include "error".red
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

  context "#verify_met?" do

    it "by default, it should call met?" do
      task.should_receive(:met?).and_return(false)

      task.verify_met?.should be false
    end
  end

  context "#step" do

    before :each do
      Kernel.stub(:sleep).with(anything).and_return(1.0)
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
        task.stub(:meet).with(anything).and_return(true)
        task.stub(:met?).with(anything).and_return(true)
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
        task.should_receive(:verify_met?).with(0).and_return(true)
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
        task.should_receive(:meet).with(0).and_return false
        task.should_receive(:meet).with(1).and_return false
        task.should_receive(:meet).with(2).and_return false
        task.step
        task.should be_failed
        task.cause_of_failure.message.should eq "Task 'test-task' failed as calling #meet() indicated failure by returning nil or false."
      end

      it "should verify is met, and if it isn't, it should be marked as failed" do
        task.should_receive(:verify_met?).with(0).and_return(false)
        task.should_receive(:verify_met?).with(1).and_return(false)
        task.should_receive(:verify_met?).with(2).and_return(false)
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

  context "self.wait_for" do
    let(:try_keeper) { double("(re)try keeper") }

    before :each do
      Time.stub(:now).and_return(0, 0.01, 1.0, 2.0, 3.0, 4.0, 5.0)
      Kernel.stub(:sleep).with(1.0).and_return(600.0)
    end

    context "when successful" do

      (1..3).each do | i | 
        context "on retry ##{i}" do
          before :each do
            try_sequence = Array.new(i - 1) { false } << true
            try_keeper.should_receive(:try).and_return(*try_sequence)
          end

          it "should return duration hash" do
            Politburo::Dependencies::Task.wait_for { try_keeper.try }.should eq(duration: i.to_f)
          end

        end
      end

    end

    it "should yield the retry count (zero based) as an argument to the block" do
      try_keeper.should_receive(:try).and_return(false, false, true)
      retries = []
      Politburo::Dependencies::Task.wait_for { | try | retries << try; try_keeper.try }

      retries.should eq [0, 1, 2]
    end

    context "when successful on last try, which would bring it over timeout" do

      it "should still be successful" do
        try_keeper.should_receive(:try).and_return(false, true)

        Politburo::Dependencies::Task.wait_for(1.5) { try_keeper.try }.should eq(duration: 2.0)
      end

    end

    context "when timed out" do

      it "should return false" do
        try_keeper.should_receive(:try).once.and_return(false)
        Politburo::Dependencies::Task.wait_for(0.5) { try_keeper.try }.should be false
      end
    end

    context "when retried out" do

      it "should return false" do
        try_keeper.should_receive(:try).exactly(5).times.and_return(false)
        Politburo::Dependencies::Task.wait_for(600.0, 5) { try_keeper.try }.should be false
      end
    end

  end
end