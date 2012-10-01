require 'politburo'
require 'ostruct'

describe Politburo::Dependencies::Runner, "integration" do

  class TestTaskA < OpenStruct
    include Politburo::Dependencies::Task
  end

  def task(name, *deps)
    task = TestTaskA.new(name: name.to_s, prerequisites: deps)
    task.stub(:met?).and_return(false, true)
    task.stub(:meet)
    #task.logger.level = Logger::ERROR
    task
  end

  def tasks(level = 1, levels_left = 0, count = 1)
    Array.new(count) do | i | 
      prereqs = levels_left > 0 ? tasks(level + 1, levels_left - 1, count) : []
      task("Task #{level}.#{i}", *prereqs)
    end
  end

  it "should run a one node tree correctly when task failed" do
    task_a = task(:a)
    task_a.should_receive(:met?).and_return(false, false)
    task_a.should_receive(:meet)

    runner = Politburo::Dependencies::Runner.new(task_a)
    runner.run()

    task_a.should_not be_done
  end

  (1..5).each do | i | 
    let(:tasks_to_run) { tasks(1, i, i == 1 ? 1 : 2) }

    it "should run a #{i} levels node tree" do
      runner = Politburo::Dependencies::Runner.new(*tasks_to_run)
      runner.run()

      tasks_to_run.each { | t | t.should be_done }
    end
  end

end