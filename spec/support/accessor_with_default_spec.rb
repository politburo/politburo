describe Politburo::Support::AccessorWithDefault do

  let(:klass) do
    Class.new do
      include Politburo::Support::AccessorWithDefault
    end
  end

  let(:has_accessor) do 
    Class.new(klass) do
      attr_reader_with_default(:log_level) { :default_level }
      attr_writer :log_level

      attr_accessor_with_default(:another_log_level) { :default_level }
    end.new
  end
 
  context "#attr_reader_with_default" do

    it "should raise an error if no block given" do
      lambda do 
        Class.new(klass) do
          attr_reader_with_default :name
        end

      end.should raise_error "attr_reader_with_default requires a block that initializes the default value."
    end

    it "should define a reader" do
      has_accessor.should respond_to(:log_level)
    end

    it "should revert to default if not set" do
      has_accessor.log_level.should be :default_level

      has_accessor.instance_eval { @log_level }.should_not be_nil
    end

    it "should read set value when set" do
      has_accessor.log_level = :override
      has_accessor.log_level.should be :override
    end
  end

  context "#attr_accessor_with_default" do
    it "should call attr_reader_with_default and attr_writer appropriately" do
      klass.should_receive(:attr_reader_with_default).with(:attr_name)

      klass.should_receive(:attr_writer).with(:attr_name)

      klass.instance_eval do 
        attr_accessor_with_default(:attr_name) { 'default' }
      end
    end

    it "should revert to default if not set" do
      has_accessor.another_log_level.should be :default_level
    end

    it "should read set value when set" do
      has_accessor.another_log_level = :override
      has_accessor.another_log_level.should be :override
    end

  end
end