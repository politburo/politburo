describe Politburo::Resource::Root do
  let(:root) { Politburo::Resource::Root.new(name: "Root") }

  it { root.should be_a Politburo::Resource::Base }

  it("should have its own context class") { root.context_class.should be Politburo::Resource::RootContext }

  it("should not have a parent resource") { root.parent_resource.should be nil }
  it("should be its own root") { root.root.should be root }
end