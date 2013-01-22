require 'politburo'

describe Politburo::Resource::Facet do

  let(:parent_resource) { Politburo::Resource::Base.new(name: "Parent resource") }
  let(:facet) { Politburo::Resource::Facet.new(name: "Facet resource") }

  before :each do
    parent_resource.add_child(facet)
  end

end
