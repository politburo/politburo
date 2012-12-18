describe Politburo::Support::HasLogger do

  let(:klass) do

    Class.new do
      include Politburo::Support::HasLogger
    end

  end

  let(:has_logger) { klass.new() }
 
  it "should have a default log level" do
    has_logger.log_level.should be Logger::INFO
  end

  it "should have a logger" do
    has_logger.logger.should_not be_nil
  end

  it "should use the log formatter" do
    has_logger.logger_output = StringIO.new
    has_logger.logger.info("This message should go through the log formatter")

    has_logger.logger_output.string.should =~ /.*\tThis message should go through the log formatter/
  end


end