describe Politburo::Tasks::RemoteCommand, "functional" do

  let(:logger) { Logger.new(STDOUT) }

  let(:remote_command) { 
    Politburo::Tasks::RemoteCommand.new(command_string, logger)
  }

  let(:user) { ENV['USER'] }

  let(:session) { Net::SSH.start("localhost", user) }

  let(:result) { 
    result = nil
    channel = session.open_channel do | channel |
      result = remote_command.execute(channel)
    end
    channel.wait
    result
  }

  before(:each) { result }

  context "when command succeeds" do
    let(:command_string) { "which ls" }

    it "should return the execution result" do
      result.should_not be_nil
      remote_command.execution_result.should_not be_nil
      remote_command.execution_result.should be result
    end

    it "should have the correct output" do
      remote_command.captured_output.string.should include "ls"
    end

  end

  context "when command fails" do
    let(:command_string) { "which banana" }

    it "should return nil but should have the result available in execution result" do
      result.should be_nil
      remote_command.execution_result.should_not be_nil
    end
  end

end
