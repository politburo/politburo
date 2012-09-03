require 'politburo'
require 'ostruct'

describe Politburo::Dependencies::Runner do

  class TestTask < OpenStruct
    include Politburo::Dependencies::Task
  end

  def task(name, *deps)
    TestTask.new(name: name.to_s, prerequisites: deps)
  end

  let(:task_a) { task(:a) }
  let(:task_b) { task(:b, task_a) }
  let(:task_c) { task(:c, task_b) }

  let(:runner) do
    runner = Politburo::Dependencies::Runner.new(task_a, task_b)
  end

  it "should store the startup tasks in the starter queue" do
    runner.start_with.should include task_a
    runner.start_with.should include task_b
  end

  context "#pick_next_task" do

    it "should pick the next leaf task that is idle" do
    end
    
  end

  it "should detect when a state failed to be met after running" do
    fail("todo")
  end

  it "should identify when a cyclical dependency has occured" do
    fail("todo")
  end
end