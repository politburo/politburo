describe Politburo::Plugins::Cloud::KeyPair do

  let(:parent_resource) { Politburo::Resource::Base.new(name: "Parent resource") }
  let(:key_pair) { Politburo::Plugins::Cloud::KeyPair.new(name: "Key pair resource") }

  before :each do
    parent_resource.add_child(key_pair)
  end

  context "#cloud_counterpart_name" do

    it "should default to the parent's short name" do
      key_pair.cloud_counterpart_name.should eq parent_resource.name
    end
  end

  context "#cloud_counterpart" do
    it "should call cloud_key_pair" do
      key_pair.should_receive(:cloud_key_pair)
      key_pair.cloud_counterpart
    end
  end

  context "cloud_key_pair" do
    let(:provider) { double("provider") }

    it "should use the provider to return the appropriate security group" do
      key_pair.should_receive(:cloud_provider).and_return(provider)
      provider.should_receive(:find_key_pair_for).with(key_pair).and_return(:cloud_key_pair)

      key_pair.cloud_key_pair.should be :cloud_key_pair
    end
  end

end
