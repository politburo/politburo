describe Politburo::Resource::HasDependencies do

  let(:dependent_obj_class) {
    Class.new do
      include Politburo::Resource::HasDependencies

      def initialize()
      end

    end
  }

  let(:dependency) { double("a dep") }
  let(:dependent_obj) { 
    obj = dependent_obj_class.new() 
    obj.dependencies << dependency
    obj
  }

  context "#dependencies" do

    it "should maintain an array of dependencies" do
      dependent_obj.dependencies.should_not be_empty
      dependent_obj.dependencies.should include(dependency)
    end

  end

  context "#dependent_on?" do

    it "should return true when dependent on specified object" do
      dependent_obj.should be_dependent_on dependency
    end

  end

  context "#add_dependency_on" do

    let(:non_dependency) { double("not a dep") }
    let(:obj_with_no_to_task) { double("can't be resolved to a task" )}
    let(:dependency_with_no_task) { double("dep with no to_task", as_dependency: obj_with_no_to_task )}

    before :each do
      dependent_obj.dependencies.clear

      dependency.stub(:to_task).and_return(dependency)
    end

    it "should raise an error if target does not respond to #as_dependency" do
      lambda { dependent_obj.add_dependency_on(non_dependency) }.should raise_error "Can't add dependency on object that doesn't respond to #as_dependency"
    end

    it "should call #as_dependency on target and add the result of that to dependencies" do
      dependent_obj.dependencies.should be_empty
      dependency.should_receive(:as_dependency).and_return(dependency)

      dependent_obj.add_dependency_on(dependency)
    end

    it "should raise an error if the target as a dependency does not respond to #to_task" do
      lambda { dependent_obj.add_dependency_on(dependency_with_no_task) }.should raise_error "Can't add dependency on a target that can't be resolved to a task"
    end

  end
end