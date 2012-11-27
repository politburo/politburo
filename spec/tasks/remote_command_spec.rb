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
    remote_command.stdin.should be STDIN
  end

  context "#repack" do

    context "when the parameter is a remote command object" do

      before :each do
        remote_command.should_receive(:kind_of?).with(Politburo::Tasks::RemoteCommand).and_return(true)
      end

      it "should simply return the object" do
        Politburo::Tasks::RemoteCommand.repack(remote_command).should be remote_command
      end

    end

    context "when the parameter is not a remote command object" do
      let(:not_a_remote_command) { double("not a remote command") }
      let(:a_string) { "just a string" }

      before :each do
        not_a_remote_command.should_receive(:kind_of?).with(Politburo::Tasks::RemoteCommand).and_return(false)
      end

      it "should convert it to a string, and pack it through unix_command" do
        not_a_remote_command.should_receive(:to_s).and_return(a_string)
        Politburo::Tasks::RemoteCommand.should_receive(:unix_command).with(a_string, :execution_output_match_pattern, :stdin, :stdout, :stderr).and_return(:a_new_command)

        Politburo::Tasks::RemoteCommand.repack(not_a_remote_command, :execution_output_match_pattern, :stdin, :stdout, :stderr).should be :a_new_command
      end

    end

  end

  context "#execute" do

    let(:ssh_channel) {  double("SSH channel") }

    before :each do
      ssh_channel.stub(:exec).with("command here; echo $?").and_yield(ssh_channel, true)
      ssh_channel.stub(:wait)
      ssh_channel.stub(:on_data)
      ssh_channel.stub(:on_extended_data)
      ssh_channel.stub(:on_close)
      ssh_channel.stub(:on_request)
      ssh_channel.stub(:request_pty).and_yield(ssh_channel, true)

      remote_command.validate_success_block.stub(:call).with(remote_command, anything).and_return(true)
    end

    context "with tty enabled" do
      before(:each) { remote_command.use_tty = true }

      it "should attempt to start pty" do
        ssh_channel.should_receive(:request_pty).and_yield(ssh_channel, true)

        remote_command.execute(ssh_channel)
      end

      it "should throw an error if it didn't successfully request pty" do
        ssh_channel.should_receive(:request_pty).and_yield(ssh_channel, false)

        lambda { remote_command.execute(ssh_channel) }.should raise_error "Failed to get interactive shell (pty) on SSH session."
      end
    end

    context "when successfully started remote command execution" do

      before :each do
        ssh_channel.should_receive(:exec).with("command here; echo $?").and_yield(ssh_channel, true)
        ssh_channel.should_receive(:wait)
        ssh_channel.stub(:on_data)
        ssh_channel.stub(:on_extended_data)
        ssh_channel.stub(:on_close)
        ssh_channel.stub(:on_request)

        remote_command.validate_success_block.stub(:call).with(remote_command, anything).and_return(true)
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

      it "should store the exit status in the execution result" do
        ssh_channel.should_receive(:on_request).with("exit-status").and_yield(ssh_channel, double("exit status data", :read_long => 127))

        remote_command.execute(ssh_channel)

        remote_command.execution_result.should include(:exit_status)
        remote_command.execution_result[:exit_status].should == 127
      end

      it "should store the exit signal in the execution result" do
        ssh_channel.should_receive(:on_request).with("exit-signal").and_yield(ssh_channel, double("exit signal data", :read_long => 127))

        remote_command.execute(ssh_channel)

        remote_command.execution_result.should include(:exit_signal)
        remote_command.execution_result[:exit_signal].should == 127
      end

      context "and the match pattern is nil" do
        it "should return empty result" do
          remote_command.should_receive(:execution_output_match_pattern).and_return(nil)

          remote_command.execute(ssh_channel).should be_empty
        end        
      end

      context "and remote command output does not match pattern" do
        it "should return empty result" do
          ssh_channel.should_receive(:on_data).and_yield(ssh_channel, "Output to standard output, no exit code after. Oops.\n")

          remote_command.execute(ssh_channel).should be_empty
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
          remote_command.execution_result.should include :exit_code
          remote_command.execution_result[:exit_code].should == "127"
        end

        context "when the validation block return true" do
          before :each do
            remote_command.validate_success_block.should_receive(:call).with(remote_command, { exit_code: '127' }).and_return(true)
          end

          it "should return the result hash" do
            remote_command.execute(ssh_channel).should be_a Hash
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