describe Politburo::Resource::Root do
  let(:root) { Politburo::Resource::Root.new(name: "Root") }

  it { root.should be_a Politburo::Resource::Base }
end