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
      fail("todo")
    end
    
    it "should detect when a task failed not provide additional tasks" do
      sub_prerequisite_a.state = :failed
      runner.pick_next_task.should == sub_prerequisite_a
    end

    it "should return nil when there are no tasks to execute" do
      sub_prerequisite_a.state = :executing
      sub_prerequisite_b.state = :executing
      runner.pick_next_task.should be_nil
    end

  end
end