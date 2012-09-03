describe Politburo::Dependencies::Task do 
  
  class TestTask < OpenStruct
    include Politburo::Dependencies::Task
  end

  let(:task) { TestTask.new }

  it "should start in a unexecuted state" do
    task.should be_unexecuted
    task.state.should == :unexecuted
  end

  it "should raise an error if set in an unknown state" do
    lambda { task.state = :silly }.should raise_error "Unknown state: silly"
  end

  context "#fiber" do

    before :each do
      task.stub(:met?).and_return(false)
      task.fiber.should_not be_nil
    end

    it "should initially pause in unexecuted state" do
      task.should be_unexecuted
    end

    context "when checking if met" do

      it "should then check if it is met, if it isn't it should set state as ready to meet" do
        task.should_receive(:met?).and_return(false)
        task.fiber.resume
        task.should be_ready_to_meet
      end

      it "should check if it is met, if it is it should set state as met" do
        task.should_receive(:met?).and_return(true)
        task.fiber.resume
        task.should be_satisfied
      end

      it "should check if it is met, if met raises an error it should set the task as failed" do
        task.should_receive(:met?).and_raise "Whoops"
        task.fiber.resume
        task.should be_failed
      end

    end

    context "when checked if met and is ready to execute" do

      before :each do
        task.fiber.resume
        task.should be_ready_to_meet
        task.stub(:meet).and_return(true)
        task.stub(:met?).and_return(true)
      end

      it "should attempt to meet, and if successful should be satisfied" do
        task.should_receive(:meet).and_return(true)
        task.fiber.resume
        task.should be_satisfied
      end

      it "should attempt to meet, and if it fails, it should be marked as failed" do
        task.should_receive(:meet).and_raise "Whoops"
        task.fiber.resume
        task.should be_failed
      end

      it "should verify is met, and if it isn't, it should be marked as failed" do
        task.should_receive(:met?).and_return(false)
        task.fiber.resume
        task.should be_failed
      end
    end

  end
end