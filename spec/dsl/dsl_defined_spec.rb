require 'politburo'

describe Politburo::DSL::DslDefined do
	
	class DslDefinedObj
		include Politburo::DSL::DslDefined

		requires :name
		requires :description

		attr_accessor :name
		attr_accessor :description
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

	context "#requires" do

		it "should add a validation lambda that verifies non blankness of instance variable" do
			dsl_defined_obj.should be_valid

			dsl_defined_obj.name = nil
			dsl_defined_obj.should_not be_valid
		end

	end

end