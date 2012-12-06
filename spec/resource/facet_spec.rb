require 'politburo'

describe Politburo::Resource::Facet do

  let(:parent_resource) { Politburo::Resource::Base.new(name: "Parent resource") }
  let(:facet) do 
    Politburo::Resource::Facet.new(parent_resource: parent_resource, name: "Facet resource")
  end

  context "#provider" do

    it "should inherit provider" do
      parent_resource.should_receive(:provider).and_return(:simple)

      facet.provider.should be :simple
    end

    it "should require a provider" do
      parent_resource.should_receive(:provider).and_return(nil)
      facet.provider = nil
      facet.should_not be_valid
    end

  end

  context "#availability_zone" do

    it "should inherit availability_zone" do
      parent_resource.should_receive(:availability_zone).and_return(:us_west_1)

      facet.availability_zone.should be :us_west_1
    end

  end

  context "#provider_config" do

    it "should inherit provider_config" do
      parent_resource.should_receive(:provider_config).and_return(:config)

      facet.provider_config.should be :config
    end

  end

end
