require 'politburo'
require 'stringio'

describe Politburo::CLI do 
    it "should print help when not command provided" do
      lambda { 
        capture(:stdout, :stderr) { Politburo::CLI.start([]) } 
      }.should raise_error SystemExit

      output.should_not be_nil
      output.should_not be_empty
      output.should include "politburo [options]"
      output.should include "--version"
      output.should include "--help"
    end

    it "should print version when asked, and exit" do
      lambda { 
        capture(:stdout, :stderr) { Politburo::CLI.start(%w(--version)) } 
      }.should raise_error SystemExit

      output.should_not be_nil
      output.should_not be_empty
      output.should include "politburo, version"
    end

    let(:output_io) { StringIO.new }
    let(:output) { output_io.string }

    def capture(*streams)
      original_stderr = $stderr
      original_stdout = $stdout

      streams.map! { |stream| stream.to_s }
      begin
        streams.each do |stream| 
          begin
            eval "$#{stream} = output_io"
          rescue => e
            original_stdout.puts e
          end
        end
        yield
      ensure
        streams.each { |stream| eval("$#{stream} = #{stream.upcase}") }
        output
      end

    end



end