describe Politburo::Support::Console do

  let(:console) { Politburo::Support::Console.new() { | s | "formatted #{s}"}}

  it "should initialize correctly" do 
    console.format_block.should_not be_nil
    console.format("string").should == "formatted string"

    console.writer.should_not be_nil
    console.writer.should be_a IO
    console.reader.should_not be_nil
    console.reader.should be_a IO
  end

  context "#format" do
    let (:format_block) { double("format block") }

    it "should use the format block to format the string" do
      console.should_receive(:format_block).and_return(format_block)
      format_block.should_receive(:call).with("string").and_return("a formatted string")

      console.format("string").should == "a formatted string"
    end

  end
  
  context "#close" do

    it "should close the writer and reader" do
      console.writer.should_receive(:close)
      console.reader.should_receive(:close)

      console.close
    end
  end
end