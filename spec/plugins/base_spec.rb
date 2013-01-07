describe Politburo::Plugins::Base do
  let(:plugin) { Politburo::Plugins::Base.new(name: 'test plugin') }

  it { plugin.should be_a Politburo::Resource::Base }

end
