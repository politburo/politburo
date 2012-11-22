describe Politburo::Support::Console do

  let(:console) { Politburo::Support::Console.new('prefix')}

  it "should initialize correctly" do 
    console.prefix.should == 'prefix'

    console.writer.should_not be_nil
    console.writer.should be_a IO
    console.reader.should_not be_nil
    console.reader.should be_a IO
  end
  
end