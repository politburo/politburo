describe Politburo::Resource::HasHierarchy do
  let(:resource_class) {
    Class.new {
      include Politburo::Resource::HasHierarchy

      def add_dependency_on(dep)
      end
    }
  }

  let(:resource) { resource_class.new() }
  let(:parent_resource) { resource_class.new() }
  let(:sub_resource_1) { resource_class.new() }
  let(:sub_resource_2) { resource_class.new() }

  before :each do
    parent_resource.add_child(resource)
    resource.add_child(sub_resource_1)
    resource.add_child(sub_resource_2)
  end

  context "#children" do

    it "should maintain a list of children" do
      parent_resource.children.should_not be_empty
      parent_resource.children.length.should == 1
      parent_resource.children.first.should == resource

      resource.children.should_not be_empty
      resource.children.length.should == 2
      resource.children.should include(sub_resource_1)
      resource.children.should include(sub_resource_2)
    end
  end

  context "#add_child" do

    it "should add the child to the children's list" do
      resource.children.should_receive(:<<).with(sub_resource_1)

      resource.add_child(sub_resource_1)
    end

    it "should add the child as a dependency" do
      resource.should_receive(:add_dependency_on).with(sub_resource_1)

      resource.add_child(sub_resource_1)

      resource.children.should include sub_resource_1
    end

    it "should set the child's parent resource" do
      sub_resource_1.should_receive(:parent_resource=).with(resource)

      resource.add_child(sub_resource_1)

      resource.children.should include sub_resource_1
    end
  end

end