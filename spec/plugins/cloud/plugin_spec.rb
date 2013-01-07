describe Politburo::Plugins::Cloud::Plugin do
  let(:plugin) { Politburo::Plugins::Cloud::Plugin.new(name: 'test cloud plugin') }

  it { plugin.should be_a Politburo::Plugins::Plugin }

  it "should add itself to the default plugins" do
    Politburo::DSL.default_plugins.should include Politburo::Plugins::Cloud::Plugin
  end

end
