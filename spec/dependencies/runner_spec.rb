require 'politburo'
require 'ostruct'

describe Politburo::Dependencies::Runner, "unit" do

  class TestTask < OpenStruct
    include Politburo::Dependencies::Task
  end

  def task(name, *deps)
    task = TestTask.new(name: name.to_s, prerequisites: deps)

    task.stub(:met?).and_return(false, true)
    task.stub(:meet)

    task.logger.level = Logger::ERROR
    task
  end

  let(:goal_a) { task(:goal_a, prerequisite_a, goal_b) }
  let(:goal_b) { task(:goal_b, prerequisite_b) }
  let(:prerequisite_a) { task(:prerequisite_a) }
  let(:prerequisite_b) { task(:prerequisite_b, sub_prerequisite_a, sub_prerequisite_b) }
  let(:sub_prerequisite_a) { task(:sub_prerequisite_a) }
  let(:sub_prerequisite_b) { task(:sub_prerequisite_b) }

  let(:runner) do
    runner = Politburo::Dependencies::Runner.new(goal_a, goal_b)
    runner.logger.level = Logger::ERROR

    runner
  end

  it "should store the startup tasks in the starter queue" do
    runner.start_with.should include goal_a
    runner.start_with.should include goal_b
  end

  context "#pick_next_task" do
    before :each do
      prerequisite_a.state = :satisfied
    end

    it "should pick the next leaf task that is idle" do
      runner.pick_next_task.should == sub_prerequisite_a
      sub_prerequisite_a.state = :executing
      runner.pick_next_task.should == sub_prerequisite_b
    end

    it "should set the paths for the tasks visited" do
      runner.pick_next_task.should == sub_prerequisite_a

      sub_prerequisite_a.primary_path.map(&:name).join(' -> ').should eq "goal_a -> goal_b -> prerequisite_b"
    end

    it "should raise an error if there's a cyclical dependency" do
      sub_prerequisite_b.prerequisites << goal_a

      lambda { runner.pick_next_task }.should raise_error "Cyclical dependency detected. Task 'goal_a' is prerequisite of itself. Cycle: goal_a -> goal_b -> prerequisite_b -> sub_prerequisite_b -> goal_a"
    end
    
    it "should detect when a task failed and not provide additional tasks" do
      sub_prerequisite_a.state = :failed
      runner.pick_next_task.should == sub_prerequisite_a
    end

    it "should return nil when there are no available tasks to execute" do
      sub_prerequisite_a.state = :executing
      sub_prerequisite_b.state = :executing
      runner.pick_next_task.should be_nil
    end

    it "should return nil when there are no more tasks to execute because they all completed" do
      sub_prerequisite_a.state = :satisfied
      sub_prerequisite_b.state = :satisfied
      prerequisite_b.state = :satisfied
      goal_b.state = :satisfied
      goal_a.state = :satisfied

      runner.pick_next_task.should be_nil
    end

  end

  context "#clear_progress_flag_on_done_tasks" do
    let (:done_tasks) { Array.new(5) { | i | double("Task #{i}", :failed? => false) } }

    before :each do
      runner.stub(:done_tasks_queue).at_least(1).and_return(done_tasks)
      done_tasks.each { | task | task.stub(:in_progress=).with(false) }
    end

    it "should iterate over done tasks queue and set progress to false" do
      runner.should_receive(:done_tasks_queue).at_least(1).and_return(done_tasks)
      done_tasks.each { | task | task.should_receive(:in_progress=).with(false) }

      runner.clear_progress_flag_on_done_tasks

      runner.failed_tasks.should be_empty
    end

    it "should identify failed tasks and add them to the failed task list" do
      first_task = done_tasks.first
      last_task = done_tasks.last

      first_task.should_receive(:failed?).and_return(true)
      last_task.should_receive(:failed?).and_return(true)

      runner.clear_progress_flag_on_done_tasks

      runner.failed_tasks.should_not be_empty
      runner.failed_tasks.should include first_task
      runner.failed_tasks.should include last_task
    end
  end

  context "#scheduler_step" do
    let(:available_task) { goal_b }

    it "should clear the progress flag on done tasks" do
      runner.should_receive(:clear_progress_flag_on_done_tasks)

      runner.scheduler_step
    end

    it "should return immediately if failed tasks exist" do
      runner.failed_tasks.should_receive(:empty?).and_return(false)
      runner.should_not_receive(:pick_next_task)

      runner.scheduler_step
    end

    it "when a non failed task is available, should pick the next task and enqueue it" do
      runner.should_receive(:pick_next_task).and_return(available_task)
      available_task.should_receive(:available_for_queueing?).and_return(true)
      available_task.should_receive(:step)
      available_task.should_receive(:in_progress=).with(true)
      runner.execution_queue.should_receive(:push).with(available_task)

      runner.scheduler_step
    end

    it "when a no task is currently available" do
      runner.should_receive(:pick_next_task).and_return(nil)
      runner.execution_queue.should_not_receive(:push)
      Kernel.should_receive(:sleep).with(0.01)

      runner.scheduler_step
    end

  end

  context "#run" do

    let(:consumer_thread_1) { double('fake thread 1', :exit => true, :join => true) }
    let(:consumer_thread_2) { double('fake thread 2', :exit => true, :join => true) }

    let(:consumer_threads) { [ consumer_thread_1, consumer_thread_2 ] }

    before :each do
      runner.stub(:terminate?).and_return(true)
      runner.stub(:task_consumer_threads).and_return(consumer_threads)
    end

    it "should run while not terminated" do
      runner.should_receive(:terminate?).and_return(false, false, false, false, true)
      runner.should_receive(:scheduler_step).exactly(4).times
      runner.run
    end

    it "should exit consumer threads" do
      consumer_thread_1.should_receive(:exit)
      consumer_thread_2.should_receive(:exit)

      consumer_thread_1.should_receive(:join)
      consumer_thread_2.should_receive(:join)

      runner.run
    end

    context "when there are failed tasks" do
      let(:failed_tasks) { [ goal_a, goal_b ] }

      it "should report on failed tasks and return false" do
        runner.should_receive(:failed_tasks).twice.and_return(failed_tasks)

        failed_tasks.each do | failed_task |
          failed_task.should_receive(:cause_of_failure).twice.and_return( RuntimeError.new("fake error") )
          runner.logger.should_receive(:error)
        end

        runner.run.should be_false
      end
    end

    context "when there are no failed tasks" do

      it "should return true" do
        runner.run.should be_true
      end
    end

  end

  context "#task_consumer_threads" do

    it "should create consumer_threads_count fiber consumer threads" do
      runner.should_receive(:task_consumer_thread_count).and_return(5)
      runner.should_receive(:create_task_consumer_thread).exactly(5).times.and_return { double("fake thread") }

      runner.task_consumer_threads.should_not be_empty
      runner.task_consumer_threads.length.should == 5
    end

  end

  context "#task_consumer_step" do
    let (:a_task) { double("task", :name => 'name') }

    it "should work its magic like fire" do
      runner.execution_queue.should_receive(:pop).and_return(a_task)
      a_task.should_receive(:step)

      runner.done_tasks_queue.should_receive(:push).with(a_task)

      runner.task_consumer_step
    end

  end

  context "#terminate?" do

    let(:failed_task) { sub_prerequisite_a.state = :failed; sub_prerequisite_a }

    it "should return true if failed_tasks is not empty" do
      runner.failed_tasks.should_receive(:empty?).and_return(false)

      runner.should be_terminate
    end

    it "should return true when pick_next_task returns a failed task" do
      runner.should_receive(:pick_next_task).and_return(failed_task)

      runner.should be_terminate
    end

    it "should return true when pick_next_task returns nil and all starter goals are done" do
      runner.should_receive(:pick_next_task).and_return(nil)
      goal_a.should_receive(:done?).and_return(true)
      goal_b.should_receive(:done?).and_return(true)

      runner.should be_terminate
    end

    it "should return false if pick_next_task returns an available task" do
      runner.should_receive(:pick_next_task).and_return(goal_b)

      runner.should_not be_terminate
    end

  end

end