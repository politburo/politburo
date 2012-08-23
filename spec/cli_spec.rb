require 'politburo'
require 'stringio'

describe Politburo::CLI do 

  context "normal running" do

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
      cli.log.stub(:debug)
      cli.log.stub(:trace)
      cli.log.stub(:info)
    end

    context "#root" do
      it "should parse the envfile contents into the root context" do
        cli.root.should_not be_nil
        cli.root.children.size.should == 2
      end

    end

    context "#babushka_sources_path" do

      let (:fake_babushka_sources_pathname) { double("fake babushka sources pathname") }

      before :each do
        cli.options.should_receive(:[]).with(:'babushka-sources-dir').and_return(:fake_babushka_sources_dir)
        File.should_receive(:expand_path).with(:fake_babushka_sources_dir).and_return(:fake_expanded_babushka_sources_dir)
        Pathname.should_receive(:new).with(:fake_expanded_babushka_sources_dir).and_return(fake_babushka_sources_pathname)
      end

      it "should use the babushka-sources-dir option to construct the babushka dir" do
        fake_babushka_sources_pathname.should_receive(:directory?).and_return(true)

        cli.babushka_sources_path.should == fake_babushka_sources_pathname
      end

      it "should raise an error if the end result isn't a valid directory" do
        fake_babushka_sources_pathname.should_receive(:directory?).and_return(false)

        lambda { cli.babushka_sources_path}.should raise_error
      end

    end

    context "#target_generation_path" do

      let (:fake_babushka_sources_pathname) { double("fake babushka sources pathname") }
      let (:fake_target_path) { double("fake target path") }
      let (:fake_time) { double('fake time') }
      let (:fake_time_as_i) { double('fake time as integer') }

      before :each do
        cli.should_receive(:babushka_sources_path).and_return(fake_babushka_sources_pathname)
        
        Time.should_receive(:now).and_return(fake_time) 
        fake_time.should_receive(:to_i).and_return(fake_time_as_i)
        fake_time_as_i.should_receive(:to_s).and_return('generated-timestamp')

        fake_babushka_sources_pathname.should_receive(:+).with('politburo-generated-timestamp').and_return(fake_target_path)

        fake_target_path.stub(:realpath).and_return("fake real path")

        fake_target_path.should_receive(:mkdir)
        fake_target_path.stub(:directory?).and_return(true)
      end

      it "should use the babushka_sources_dir and timestamp to generate a target dir" do
        cli.target_generation_path.should == fake_target_path
      end

      it "should raise an error if the directory wasn't created" do
        fake_target_path.should_receive(:directory?).and_return(false)

        lambda { cli.target_generation_path }.should raise_error "Could not create target generation path: 'fake real path'"
      end

      it "should be memoised so it returns the same target path the 2nd time around" do
        cli.target_generation_path.should == cli.target_generation_path
      end

    end

    context "#generate_to" do

      let(:file_double) { double("fake file") }
      let(:target_dir) { double("fake dir s") }

      it "should write the babushka deps into a file in the specified source directory" do
        cli.root.should_receive(:to_babushka_deps).and_return(:fake_deps_s)
        File.should_receive(:join).with(target_dir, 'politburo_generated_deps.rb').and_return(:fake_combined_path)
        File.should_receive(:open).with(:fake_combined_path, "w").and_yield(file_double)
        file_double.should_receive(:write).with(:fake_deps_s)

        cli.generate_to(target_dir)
      end

    end

    context "#run" do
      let (:fake_target_path) { double("fake target path") }

      it "should generate the babushka deps file to the target directory" do
        cli.should_receive(:target_generation_path).and_return(fake_target_path)
        fake_target_path.should_receive(:realpath).and_return(:fake_target_realpath)
        cli.should_receive(:generate_to).with(:fake_target_realpath)

        cli.run
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

    context "--babushka-sources-dir" do

      context "when not provided" do
        let(:args) { %w(fake-target) }

        it "should default to ~/.babushka/sources" do
          cli.options[:'babushka-sources-dir'].should == '~/.babushka/sources'
        end
      end

      context "when provided" do
        let(:args) { %w(--babushka-sources-dir=Some-dir fake-target) }

        it "should set the source dir" do
          cli.options[:'babushka-sources-dir'].should == 'Some-dir'
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