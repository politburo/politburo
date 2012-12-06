require 'politburo'

describe Politburo::Resource::Facet do

  let(:parent_resource) { Politburo::Resource::Base.new(name: "Parent resource") }
  let(:facet) do 
    Politburo::Resource::Facet.new(parent_resource: parent_resource, name: "Facet resource")
  end

  context "#flavour" do

    it "should inherit flavour" do
      parent_resource.should_receive(:flavour).and_return(:simple)

      facet.flavour.should be :simple
    end

    it "should require a flavour" do
      parent_resource.should_receive(:flavour).and_return(nil)
      facet.flavour = nil
      facet.should_not be_valid
    end

  end

  context "#availability_zone" do

    it "should inherit availability_zone" do
      parent_resource.should_receive(:availability_zone).and_return(:us_west_1)

      facet.availability_zone.should be :us_west_1
    end

  end

end
