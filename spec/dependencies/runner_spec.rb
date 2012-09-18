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