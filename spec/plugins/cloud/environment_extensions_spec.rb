describe Politburo::Resource::Environment, "cloud extensions" do
  let(:parent_resource) { Politburo::Resource::Base.new(name: 'Parent resource') }
  let(:environment) { Politburo::Resource::Environment.new(name: "Environment resource") }

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

  describe Politburo::Resource::EnvironmentContext, "cloud extensions" do

    context "#security_group" do

      it { environment.context.security_group(name: 'Security Group') {}.receiver.should be_a Politburo::Plugins::Cloud::SecurityGroup }

    end
    
  end
end

