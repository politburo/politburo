require 'politburo'

describe Politburo::Resource::Facet do

  let(:parent_resource) { Politburo::Resource::Base.new(name: "Parent resource") }
  let(:facet) { Politburo::Resource::Facet.new(name: "Facet resource") }

  before :each do
    parent_resource.add_child(facet)
  end

  it("should have its own context class") { facet.context_class.should be Politburo::Resource::FacetContext }

end
