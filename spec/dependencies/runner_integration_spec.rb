require 'politburo'
require 'ostruct'

describe Politburo::Dependencies::Runner, "integration" do

  class TestTaskA < OpenStruct
    include Politburo::Dependencies::Task
  end

  def task(name, *deps)
    task = TestTaskA.new(name: name.to_s, prerequisites: deps)
    task.stub(:met?).and_return(false, true)
    task.stub(:meet).and_return(true)
    task.stub(:name).and_return('test-task')
    #task.logger.level = Logger::DEBUG
    task
  end

  def tasks(name_prefix, current_level, levels_left, index_in_level, total_per_level)
    # puts "Tasks called: tasks(name_prefix=#{name_prefix}, current_level=#{current_level}, levels_left=#{levels_left}, index_in_level=#{index_in_level}, total_per_level=#{total_per_level})"
    Array.new(total_per_level) do | i | 
      task_name = name_prefix.empty? ? "#{i}" : "#{name_prefix}.#{i}"
      prereqs = (levels_left > 0) ? tasks(task_name, current_level + 1, levels_left - 1, i, total_per_level) : []
      # puts "Creating task #{task_name}"
      task("Task #{task_name}", *prereqs)
    end
  end

  it "should run a one node tree correctly when task failed" do
    task_a = task(:a)
    #task_a.should_receive(:met?).exactly(1).times.and_return(false)
    #task_a.should_receive(:verify_met?).with(anything).exactly(3).times.and_return(false)
    task_a.should_receive(:meet).with(anything).and_raise("error")

    runner = Politburo::Dependencies::Runner.new(task_a)

    runner.logger.should_receive(:error)
    runner.run()

    task_a.cause_of_failure.to_s.should eq "error"


    task_a.should_not be_done
  end

  (1..4).each do | i | 

    it "should run a #{i} levels node tree" do
      tasks_to_run = tasks("", 0, (i - 1), 0, i == 1 ? 1 : 3)

      runner = Politburo::Dependencies::Runner.new(*tasks_to_run)
      #runner.logger.level = Logger::DEBUG
      runner.run()

      tasks_to_run.each { | t | t.should be_done }
    end
  end

end