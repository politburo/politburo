require 'politburo'
require 'ostruct'

describe Politburo::Dependencies::Runner do

  class TestTask < OpenStruct
    include Politburo::Dependencies::Task
  end

  def task(name, *deps)
    TestTask.new(name: name.to_s, prerequisites: deps)
  end

  let(:goal_a) { task(:goal_a, prerequisite_a, goal_b) }
  let(:goal_b) { task(:goal_b, prerequisite_b) }
  let(:prerequisite_a) { task(:prerequisite_a) }
  let(:prerequisite_b) { task(:prerequisite_b, sub_prerequisite_a, sub_prerequisite_b) }
  let(:sub_prerequisite_a) { task(:sub_prerequisite_a) }
  let(:sub_prerequisite_b) { task(:sub_prerequisite_b) }

  let(:runner) do
    runner = Politburo::Dependencies::Runner.new(goal_a, goal_b)
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

  context "#scheduler_step" do
    let(:available_task) { goal_b }
    let(:available_task_fiber) { double("fiber ho") }

    it "when a task is available, should pick the next task and enqueue it" do
      runner.should_receive(:pick_next_task).and_return(available_task)
      available_task.should_receive(:fiber).and_return(available_task_fiber)
      runner.execution_queue.should_receive(:push).with(available_task_fiber)

      runner.scheduler_step
    end

    it "when a no task is currently available" do
      runner.should_receive(:pick_next_task).and_return(nil)
      runner.execution_queue.should_not_receive(:push)
      Kernel.should_receive(:sleep).with(1)

      runner.scheduler_step
    end

  end

  context "#run" do

    let(:consumer_thread_1) { double('fake thread 1', :exit => true, :join => true) }
    let(:consumer_thread_2) { double('fake thread 2', :exit => true, :join => true) }

    let(:consumer_threads) { [ consumer_thread_1, consumer_thread_2 ] }

    before :each do
      runner.stub(:terminate?).and_return(true)
      runner.stub(:fiber_consumer_threads).and_return(consumer_threads)
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

  end

  context "#fiber_consumer_threads" do

    it "should create consumer_threads_count fiber consumer threads" do
      runner.should_receive(:fiber_consumer_thread_count).and_return(5)
      runner.should_receive(:create_fiber_consumer_thread).exactly(5).times.and_return { double("fake thread") }

      runner.fiber_consumer_threads.should_not be_empty
      runner.fiber_consumer_threads.length.should == 5
    end

  end

  context "#fiber_consumer_step" do
    let (:fiber) { double("fiber") }

    it "should work its magic like fire" do
      runner.execution_queue.should_receive(:pop).and_return(fiber)
      fiber.should_receive(:resume)

      runner.fiber_consumer_step
    end

  end

  context "#terminate?" do

    let(:failed_task) { sub_prerequisite_a.state = :failed; sub_prerequisite_a }

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