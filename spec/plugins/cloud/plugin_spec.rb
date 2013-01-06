describe Politburo::Plugins::Cloud::Plugin do
  let(:plugin) { Politburo::Plugins::Cloud::Plugin.new(name: 'test cloud plugin') }

  it { plugin.should be_a Politburo::Plugins::Plugin }

end
