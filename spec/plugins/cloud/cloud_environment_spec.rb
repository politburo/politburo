describe Politburo::Plugins::Cloud::Environment do
  let(:parent_resource) { Politburo::Resource::Base.new(name: 'Parent resource') }
  let(:environment) { Politburo::Plugins::Cloud::Environment.new(name: "Environment resource") }

  before :each do
    parent_resource.add_child(environment)
  end

  it "should require an provider" do
    environment.provider = nil
    environment.should_not be_valid
  end

  it "should allow a region" do
    environment.region = :us_west_1
    environment.region.should be :us_west_1
  end

  it "should allow a provider configuration parameter" do
    environment.provider_config = {}
    environment.provider_config.should be {}
  end

  describe Politburo::Plugins::Cloud::EnvironmentContextExtensions do

    let(:context) {
      environment.context
    }

    before :each do
      Politburo::Plugins::Cloud::EnvironmentContextExtensions.load(context)
    end

    context "#node" do
      it { context.node(name: 'Node') {}.receiver.should be_a Politburo::Plugins::Cloud::Node }
    end
    
    context "#facet" do
      it { context.facet(name: 'Facet') {}.receiver.should be_a Politburo::Plugins::Cloud::Facet }
    end
    
    context "#security_group" do

      it { context.security_group(name: 'Security Group') {}.receiver.should be_a Politburo::Plugins::Cloud::SecurityGroup }

    end
    
    context "#key_pair" do

      it { context.key_pair(name: 'Key Pair') {}.receiver.should be_a Politburo::Plugins::Cloud::KeyPair }

    end
    
  end
end

