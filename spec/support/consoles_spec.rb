describe Politburo::Support::Consoles do

  let(:consoles) { Politburo::Support::Consoles.instance }
  let(:console) { consoles.create_console() { | s | "formatted #{s}" } }

  context "#create_console" do

    it "should create a new console correctly" do 
      console.should_not be_nil
      console.format("string").should == "formatted string"
    end

    it "should retain the console" do
      consoles.items.should include console
    end

  end

  context "#watch_for_output" do

    before :each do
      Thread.stub(:new)
    end

    it "should create a thread" do
      Thread.should_receive(:new)

      consoles.watch_for_output
    end

    context "when an error happens internally" do
      before :each do
        Thread.should_receive(:new).and_yield
        consoles.should_receive(:watch_for_output_step) { raise ("Error internally") }
        consoles.output.stub(:puts)
        consoles.items.stub(:map)
      end

      it "should ensure items are closed" do
        consoles.items.should_receive(:map)

        consoles.watch_for_output
      end

      it "should output the error" do
        consoles.output.should_receive(:puts).with("Error internally")
        consoles.output.should_receive(:puts).with(anything)

        consoles.watch_for_output
      end
    end
  end

  context "#output_with_mutex" do
    let(:mutex) { double("fake mutex") }

    before :each do
      consoles.instance_variable_set(:@mutex, mutex)

      mutex.stub(:synchronize).and_yield
      consoles.output.stub(:puts).with("formatted line of text")
      console.stub(:format).with("line of text").and_return("formatted line of text")
    end

    it "should synchronize on mutex" do
      mutex.should_receive(:synchronize).and_yield

      consoles.output_with_mutex(console, "line of text")
    end

    it "should puts to the output" do
      console.should_receive(:format).with("line of text").and_return("formatted line of text")
      consoles.output.should_receive(:puts).with("formatted line of text")

      consoles.output_with_mutex(console, "line of text")
    end


  end

  context "#consoles_by_readers" do

    it "should have a mapping from reader to console" do
      console.should_not be_nil
      consoles.consoles_by_readers[console.reader].should be console
    end

  end

  context "#watch_for_output_step" do

    before :each do
      console.reader.stub(:gets).and_return("line of text")

      IO.stub(:select).with(consoles.readers, nil, nil, 30).and_return([ [ console.reader ], nil, nil ])

      consoles.stub(:output_with_mutex).with(console, anything)
    end

    it "should select the io with the readers" do
      IO.should_receive(:select).with(consoles.readers, nil, nil, 30).and_return([ [ console.reader ], nil, nil ])

      consoles.watch_for_output_step
    end

    it "should read a line from the reader" do
      console.reader.should_receive(:gets).and_return("line of text")

      consoles.watch_for_output_step
    end

    it "should output the read line" do
      consoles.should_receive(:output_with_mutex).with(console, "line of text")

      consoles.watch_for_output_step
    end
  end
end