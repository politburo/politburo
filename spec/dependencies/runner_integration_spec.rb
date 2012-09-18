require 'politburo'
require 'ostruct'

describe Politburo::Dependencies::Runner, "integration" do

  class TestTask < OpenStruct
    include Politburo::Dependencies::Task
  end

  def task(name, *deps)
    task = TestTask.new(name: name.to_s, prerequisites: deps)
    task
  end

  it "should run a one node tree" do
    task_a = task(:a)
    runner = Politburo::Dependencies::Runner.new(task_a)
    runner.run()

    task_a.should_be done
  end

end