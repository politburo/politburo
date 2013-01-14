describe Politburo::Resource::BelongsToHierarchy do

  let(:resource_class) {
    Class.new {
      include Politburo::Resource::BelongsToHierarchy

      attr_accessor :name
    }
  }

  let(:parent_resource) { res = resource_class.new(); res.name = "Parent resource"; res }
  let(:resource) { res = resource_class.new(); res.parent_resource = parent_resource; res.name = "Child resource"; res }

  context "#full_name" do
    it "should return a hierarchical name for the resource" do
      resource.full_name.should == "Parent resource:Child resource"
    end
  end

end