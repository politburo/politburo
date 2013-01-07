require 'politburo'

describe Politburo::Resource::Facet do

  let(:parent_resource) { Politburo::Resource::Base.new(name: "Parent resource") }
  let(:facet) do 
    Politburo::Resource::Facet.new(parent_resource: parent_resource, name: "Facet resource")
  end

  it("should have its own context class") { facet.context_class.should be Politburo::Resource::FacetContext }

end
