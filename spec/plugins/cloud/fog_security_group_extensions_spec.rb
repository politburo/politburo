describe Politburo::Plugins::Cloud::FogSecurityGroupExtensions do 
  let(:klass) { Class.new { include Politburo::Plugins::Cloud::FogSecurityGroupExtensions }}

  let(:security_group) { klass.new() }

  context "#display_name" do

    it "should attempt to use name as the display_name" do
      security_group.should_receive(:group_id).and_return('sg-34343')

      security_group.display_name.should eq "sg-34343"
    end

  end
end