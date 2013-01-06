describe Politburo::Plugins::Plugin do
  let(:plugin) { Politburo::Plugins::Plugin.new(name: 'test plugin') }

  it { plugin.should be_a Politburo::Resource::Base }

end
