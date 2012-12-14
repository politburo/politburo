require 'politburo'

describe Politburo::DSL::DslDefined do
	
	class DslDefinedObj
		include Politburo::DSL::DslDefined

		requires :name
		requires :description

		inherits :provider

		attr_accessor :name
		attr_accessor :description

		attr_reader_with_default(:log_level) { :default_level }
		attr_writer :log_level

		attr_accessor_with_default(:another_log_level) { :default_level }
	end

	let(:dsl_defined_obj) do
		obj = DslDefinedObj.new()

		obj.name = "Name"
		obj.description = "Description here"
		obj
	end

	it "should have a list of validation labmdas" do
		DslDefinedObj.validations.should_not be_nil
		DslDefinedObj.validations.should_not be_empty
	end

	context "#[]" do

		context "with an existing attribute accessor" do

			it "should return the value" do
				dsl_defined_obj[:name].should be dsl_defined_obj.name
			end

			it "should have indifferent access with string or symbol" do
				dsl_defined_obj["name"].should be dsl_defined_obj[:name]
			end

		end

		context "with a non-existance attribute accessor" do

			it "should return nil" do
				dsl_defined_obj[:non_existant_property].should be_nil
			end

		end

	end

	context "#context" do
		let (:context) { dsl_defined_obj.context }

		it "should lazily instantiante and return a context with this dsl defined object as the receiver" do
			Politburo::DSL::Context.should_receive(:new).with(dsl_defined_obj).and_return(:context_obj)

			dsl_defined_obj.context.should_not be_nil
			dsl_defined_obj.context.should be context
		end

	end

	context "#valid?" do
		it "should return false when validation errors exist for the obj" do
			dsl_defined_obj.description = nil

			dsl_defined_obj.validation_errors.should_not be_empty
			dsl_defined_obj.should_not be_valid
		end

		it "should return true when the obj has no validation errors" do
			dsl_defined_obj.validation_errors.should be_empty
			dsl_defined_obj.should be_valid
		end
	end

	context "#validation_errors" do

		it "should return a hash of errors raised while validating" do
			dsl_defined_obj.name = nil

			validation_errors = dsl_defined_obj.validation_errors

			validation_errors.should_not be_empty
			validation_errors.size.should == 1

			validation_errors_for_name = validation_errors[:name]
			validation_errors_for_name.should_not be_empty
			validation_errors_for_name.size.should == 1

			validation_errors_for_name.first.should be_a RuntimeError
			validation_errors_for_name.first.message.should eql("'name' is required")
		end
	end

	context "#validate!" do

		before(:each) { dsl_defined_obj.name = nil }

		it { lambda { dsl_defined_obj.validate! }.should raise_error "Validation error(s): 'name' is required" }

	end

	context "#validation_errors_for" do

		it "should return a hash of errors raised while validating" do
			dsl_defined_obj.name = nil

			validation_errors = DslDefinedObj.validation_errors_for(dsl_defined_obj)

			validation_errors.should_not be_empty
			validation_errors.size.should == 1

			validation_errors_for_name = validation_errors[:name]
			validation_errors_for_name.should_not be_empty
			validation_errors_for_name.size.should == 1

			validation_errors_for_name.first.should be_a RuntimeError
			validation_errors_for_name.first.message.should eql("'name' is required")
		end
	end

	context "#inherits" do
		let (:parent_resource) { double("parent resource") }

		it "should define an instance getter that delegates to the parent resource if doesn't have a value" do
			dsl_defined_obj.should_receive(:parent_resource).and_return(parent_resource)
			parent_resource.should_receive(:provider).and_return(:parent_provider)

			dsl_defined_obj.provider.should be :parent_provider
		end

	end

	context "#requires" do

		it "should add a validation lambda that verifies non blankness of instance variable" do
			dsl_defined_obj.should be_valid

			dsl_defined_obj.name = nil
			dsl_defined_obj.should_not be_valid
		end

	end

	context "#attr_reader_with_default" do

		it "should raise an error if no block given" do
			lambda do 
				Class.new do
					include Politburo::DSL::DslDefined

					attr_reader_with_default :name
				end

			end.should raise_error "attr_reader_with_default requires a block that initializes the default value."
		end

		it "should define a reader" do
			dsl_defined_obj.should respond_to(:log_level)
		end

		it "should revert to default if not set" do
			dsl_defined_obj.log_level.should be :default_level
		end

		it "should read set value when set" do
			dsl_defined_obj.log_level = :override
			dsl_defined_obj.log_level.should be :override
		end
	end

	context "#attr_accessor_with_default" do
		let(:klass) { Class.new { include Politburo::DSL::DslDefined } }

		it "should call attr_reader_with_default and attr_writer appropriately" do
			klass.should_receive(:attr_reader_with_default).with(:attr_name)

			klass.should_receive(:attr_writer).with(:attr_name)

			klass.instance_eval do 
				attr_accessor_with_default(:attr_name) { 'default' }
			end
		end

		it "should revert to default if not set" do
			dsl_defined_obj.another_log_level.should be :default_level
		end

		it "should read set value when set" do
			dsl_defined_obj.another_log_level = :override
			dsl_defined_obj.another_log_level.should be :override
		end

	end

end