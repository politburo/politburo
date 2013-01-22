describe Politburo::Plugins::Cloud::RootContextExtensions do
  let(:root) {
    Politburo::Resource::Root.new(name: 'root')
  }

  let(:context_class) {
    Class.new(Politburo::Resource::RootContext) {
      include Politburo::Plugins::Cloud::RootContextExtensions
    }
  }

  let(:context) {
    root.context
  }

  before :each do
    Politburo::Plugins::Cloud::RootContextExtensions.load(context)
  end

  context "#environment" do
    it { context.environment(name: 'Env', provider: :aws) {}.receiver.should be_a Politburo::Plugins::Cloud::Environment }
  end
  
  
end
