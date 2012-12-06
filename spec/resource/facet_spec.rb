require 'politburo'

describe Politburo::Resource::Facet do

  let(:parent_resource) { Politburo::Resource::Base.new(name: "Parent resource") }
  let(:facet) do 
    Politburo::Resource::Facet.new(parent_resource: parent_resource, name: "Facet resource")
  end

  context "#flavor" do

    it "should inherit flavor" do
      parent_resource.should_receive(:flavor).and_return(:simple)

      facet.flavor.should be :simple
    end

    it "should require a flavor" do
      parent_resource.should_receive(:flavor).and_return(nil)
      facet.flavor = nil
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
