require 'politburo'
require 'stringio'

describe Politburo::CLI do 

  context "#run" do

    let (:cli) { Politburo::CLI.new(options, targets) }
    let (:targets) { ['fake-target'] }
    let (:options) { { } }

    let (:envfile_contents) do
      <<ENVFILE_CONTENTS
environment(name: "environment", environment_flavour: :amazon_web_services) do
  node(name: "node", node_flavour: "m1.large") {}
  node(name: "another node", node_flavour: "m1.large") do
    depends_on node(name: "node").state(:configured)
  end
  node(name: "yet another node", node_flavour: "m1.large") do
    state('configured').depends_on node(name: "node")
  end
end

environment(name: 'another environment', environment_flavour: :amazon_web_services) do
  node(name: "a node from another galaxy", node_flavour: "c1.xlarge") {}
end
ENVFILE_CONTENTS
    end

    before(:each) do
      cli.stub(:envfile_contents).and_return(envfile_contents)
      cli.run
    end

    context "envfile" do
      it "should parse the envfile contents into the root context" do
        cli.root.should_not be_nil
        cli.root.children.size.should == 2
      end

    end

  end

  context "#create" do

    let (:cli) { cli = nil; capture(:stdout, :stderr) { cli = Politburo::CLI.create(args) }; cli }

    context "--envfile" do

      context "when not provided" do
        let(:args) { %w(fake-target) }

        it "should default to Envfile" do
          cli.options[:envfile].should == 'Envfile'
        end
      end

      context "when provided" do
        let(:args) { %w(--envfile=ProvidedEnvfile fake-target) }

        it "should set the envfile" do
          cli.options[:envfile].should == 'ProvidedEnvfile'
        end

      end

    end

    it "should print help when no targets provided" do
      lambda { 
        capture(:stdout, :stderr) { Politburo::CLI.create([]) } 
      }.should raise_error SystemExit

      output.should_not be_nil
      output.should_not be_empty
      output.should include "politburo [options]"
      output.should include "--version"
      output.should include "--help"
    end

    it "should print version when asked, and exit" do
      lambda { 
        capture(:stdout, :stderr) { Politburo::CLI.create(%w(--version)) } 
      }.should raise_error SystemExit

      output.should_not be_nil
      output.should_not be_empty
      output.should include "politburo, version"
    end

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