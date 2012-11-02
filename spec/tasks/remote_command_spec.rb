describe Politburo::Tasks::RemoteCommand do
  let(:output_stream) { StringIO.new }

  let(:remote_command) { 
    Politburo::Tasks::RemoteCommand.new(
      "command here; echo $?", /^(?<exit_code>\d*)$[^$]?\z/, 
      STDIN, 
      output_stream, 
      output_stream) { | remote_command, result | result[:exit_code] == "0" }
  }

  it "should initialize correctly" do
    remote_command.command.should == "command here; echo $?"
    remote_command.execution_output_match_pattern.should == /^(?<exit_code>\d*)$[^$]?\z/
    remote_command.validate_success_block.should_not be_nil
    remote_command.validate_success_block.should be_a Proc

    remote_command.stdout.should be output_stream
    remote_command.stderr.should be output_stream
  end

  context "#execute" do

    let(:ssh_channel) {  double("SSH channel") }

    context "when successfully started remote command execution" do

      before :each do
        ssh_channel.should_receive(:exec).with("command here; echo $?").and_yield(ssh_channel, true)
        ssh_channel.should_receive(:wait)
        ssh_channel.stub(:on_data)
        ssh_channel.stub(:on_extended_data)
        ssh_channel.stub(:on_close)
      end

      it "should print remote standard output to output stream" do
        ssh_channel.should_receive(:on_data).and_yield(ssh_channel, "output to standard output, line 1\n").and_yield(ssh_channel, "output to standard output, line 2\n")

        remote_command.stdout.should_receive(:print).with("output to standard output, line 1\n")
        remote_command.stdout.should_receive(:print).with("output to standard output, line 2\n")

        remote_command.execute(ssh_channel)
      end

      it "should print remote error output to error stream" do
        ssh_channel.should_receive(:on_extended_data).and_yield(ssh_channel, 1, "output to error output, line 1\n").and_yield(ssh_channel, 1, "output to error output, line 2\n")

        remote_command.stderr.should_receive(:print).with("output to error output, line 1\n")
        remote_command.stderr.should_receive(:print).with("output to error output, line 2\n")

        remote_command.execute(ssh_channel)
      end

      context "and remote command output does not match pattern" do
        it "should return nil" do
          ssh_channel.should_receive(:on_data).and_yield(ssh_channel, "Output to standard output, no exit code after. Oops.\n")

          remote_command.execute(ssh_channel).should be_nil
        end        
      end

      context "and remote command output matches pattern" do
        before :each do
          ssh_channel.should_receive(:on_data).
            and_yield(ssh_channel, "output to standard output, line 1\n").
            and_yield(ssh_channel, "output to standard output, line 2\n").
            and_yield(ssh_channel, "127\n")
        end

        it "should have matches in the result hash" do
          remote_command.execute(ssh_channel)
          remote_command.execution_result.should == { exit_code: '127' }
        end

        context "when the validation block return true" do
          before :each do
            remote_command.validate_success_block.should_receive(:call).with(remote_command, { exit_code: '127' }).and_return(true)
          end

          it "should return the result hash" do
            remote_command.execute(ssh_channel).should == { exit_code: '127' }
          end

        end

        context "when the validation block return false" do
          before :each do
            remote_command.validate_success_block.should_receive(:call).with(remote_command, { exit_code: '127' }).and_return(false)
          end

          it "should return nil" do
            remote_command.execute(ssh_channel).should be_nil
          end

        end

      end

    end

    context "when execution failed altogether" do
      before :each do
        ssh_channel.should_receive(:exec).with("command here; echo $?").and_yield(ssh_channel, false)
      end


      it "should raise an error" do
        
        lambda { remote_command.execute(ssh_channel) }.should raise_error("Could not execute command 'command here; echo $?'.")
      end

    end

  end

end