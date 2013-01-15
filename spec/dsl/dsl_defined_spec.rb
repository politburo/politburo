require 'politburo'

describe Politburo::DSL::DslDefined do
	
	let(:dsl_defined_class) {
		Class.new() {
			include Politburo::DSL::DslDefined

			requires :name
			requires :description

			inherits :provider

			attr_accessor :name
			attr_accessor :description
		}	
	}

	let(:dsl_defined_obj) do
		obj = dsl_defined_class.new()

		obj.name = "Name"
		obj.description = "Description here"
		obj
	end

	it "should have a list of validation labmdas" do
		dsl_defined_class.validations.should_not be_nil
		dsl_defined_class.validations.should_not be_empty
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
		let (:context_class) { double("context class")}

		it "should lazily instantiante and return a context with this dsl defined object as the receiver" do
			dsl_defined_obj.should_receive(:context_class).and_return(context_class)
			context_class.should_receive(:new).with(dsl_defined_obj).and_return(:context_obj)

			dsl_defined_obj.context.should_not be_nil
			dsl_defined_obj.context.should be context
		end

	end

	context "validations" do

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

				validation_errors = dsl_defined_class.validation_errors_for(dsl_defined_obj)

				validation_errors.should_not be_empty
				validation_errors.size.should == 1

				validation_errors_for_name = validation_errors[:name]
				validation_errors_for_name.should_not be_empty
				validation_errors_for_name.size.should == 1

				validation_errors_for_name.first.should be_a RuntimeError
				validation_errors_for_name.first.message.should eql("'name' is required")
			end
		end

		context "validations" do

			let(:dsl_defined_class_a) { 
				Class.new() { 
					include Politburo::DSL::DslDefined 

					requires :attr_a
				} 
			}

			let(:dsl_defined_class_b) { 
				Class.new(dsl_defined_class_a) {
					include Politburo::DSL::DslDefined 

					requires :attr_b
					validates(:attr_a) { does_stuff }
				} 
			}

			let(:dsl_defined_class_c) { 
				Class.new(dsl_defined_class_b) {
					include Politburo::DSL::DslDefined 

					requires :attr_c
					validates(:attr_a) { does_more_stuff }
				} 
			}

			context "::explicit_validations" do

				it "should be a class specific list of validations for this class only" do
					dsl_defined_class_a.explicit_validations.should_not be_empty
					dsl_defined_class_a.explicit_validations[:attr_a].should_not be_empty
					dsl_defined_class_a.explicit_validations[:attr_a].size.should == 1

					dsl_defined_class_b.explicit_validations.should_not be_empty
					dsl_defined_class_b.explicit_validations[:attr_b].should_not be_empty
					dsl_defined_class_b.explicit_validations[:attr_b].size.should == 1

					dsl_defined_class_b.explicit_validations[:attr_a].should_not be_empty
					dsl_defined_class_b.explicit_validations[:attr_a].size.should == 1
				end
			end

			context "::validates" do
				it "should add to explicit_validations" do
					dsl_defined_class_b.validates(:attr_a) { stuff to_validate }
					dsl_defined_class_b.explicit_validations[:attr_a].should_not be_empty
					dsl_defined_class_b.explicit_validations[:attr_a].size.should == 2
				end

			end

			context "::validations" do

				it "should aggregate all validations from superclasses down, starting with superclasses" do
					dsl_defined_class_a.validations.should eq dsl_defined_class_a.explicit_validations

					dsl_defined_class_b.validations.should_not be_empty

					dsl_defined_class_b.validations[:attr_b].should_not be_empty
					dsl_defined_class_b.validations[:attr_b].size.should == 1
					dsl_defined_class_b.validations[:attr_a].should_not be_empty
					dsl_defined_class_b.validations[:attr_a].size.should == 2

					dsl_defined_class_c.validations.should_not be_empty

					dsl_defined_class_c.validations[:attr_b].should_not be_empty
					dsl_defined_class_c.validations[:attr_b].size.should == 1
					dsl_defined_class_c.validations[:attr_c].should_not be_empty
					dsl_defined_class_c.validations[:attr_c].size.should == 1
					dsl_defined_class_c.validations[:attr_a].should_not be_empty
					dsl_defined_class_c.validations[:attr_a].size.should == 3
				end

			end


		end
	end

	context "#inherits" do
		let (:parent_resource) { double("parent resource") }

		it "should define an instance getter that delegates to the parent resource if doesn't have a value" do
			dsl_defined_obj.should_receive(:parent_resource).twice.and_return(parent_resource)
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

	context "#attr_with_default" do

		let(:class_with_attr_with_default) {
			Class.new(dsl_defined_class) {

				attr_with_default(:herring) { 'blue' }
			}
		}

		let(:obj_with_attr) {
			class_with_attr_with_default.new()
		}

		it "should add accessors for the attribute" do
			obj_with_attr.herring = 'red'
			obj_with_attr.herring.should eq 'red'
		end

		it "should revert to default if not set" do
			obj_with_attr.herring.should eq 'blue'
		end

		it "should raise an error if no block given" do
			lambda { 
				Class.new(dsl_defined_class) {
					attr_with_default(:parrot)
				}
			}.should raise_error "Block is required for default value"
		end
	end

	context "implications" do

		let(:dsl_defined_class_a) { Class.new() { include Politburo::DSL::DslDefined } }
		let(:dsl_defined_class_b) { Class.new(dsl_defined_class_a) { include Politburo::DSL::DslDefined } }
		let(:dsl_defined_class_c) { Class.new(dsl_defined_class_b) { include Politburo::DSL::DslDefined } }

		let(:implication_a) { lambda { stuff to_do } }
		let(:implication_b) { lambda { more stuff to_do } }
		let(:implication_c) { lambda { even more stuff to_do } }

		before :each do
			dsl_defined_class_a.explicitly_implied.should be_empty
			dsl_defined_class_a.explicitly_implied << implication_a
		end

		context "::explicitly_implied" do

			it "should be a class specific list of implications for this class only" do
				dsl_defined_class_a.explicitly_implied.should_not be_empty

				dsl_defined_class_b.explicitly_implied.should be_empty
			end
		end

		context "implies" do
			it "should add to explicitly_implied" do
				dsl_defined_class_b.class_eval { implies { stuff to_do } }
				dsl_defined_class_b.explicitly_implied.should_not be_empty
			end

		end

		context "::implied" do

			before :each do
				dsl_defined_class_b.explicitly_implied << implication_b
				dsl_defined_class_c.explicitly_implied << implication_c
			end

			it "should aggregate all implications from superclasses down, starting with superclasses" do
				dsl_defined_class_a.implied.should eq [ implication_a ]
				dsl_defined_class_b.implied.should eq [ implication_a, implication_b ]
				dsl_defined_class_c.implied.should eq [ implication_a, implication_b, implication_c ]
			end

		end


	end

	context "logging" do
		it "should have a log" do
			dsl_defined_obj.should be_a Politburo::Support::HasLogger
		end

		let(:parent_resource) { double(:fake_parent, log_level: Logger::DEBUG, logger_output: :fake_output) }

		before :each do
			dsl_defined_obj.stub(:parent_resource).and_return(parent_resource)
		end

		it "should be able to inherit the log level" do
			dsl_defined_obj.log_level.should be Logger::DEBUG
		end

		it "should be able to inherit the log output" do
			dsl_defined_obj.logger_output.should be :fake_output
		end

	end

end