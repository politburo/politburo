describe Politburo::Plugins::Cloud::Server do 
  let(:klass) { Class.new { include Politburo::Plugins::Cloud::Server }}

  let(:server) { klass.new() }

  context "#display_name" do

    it "should attempt to use dns_name as the display_name" do
      server.should_receive(:respond_to?).with(:dns_name).and_return(true)
      server.should_receive(:dns_name).twice.and_return(:dns_name)

      server.display_name.should be :dns_name
    end

    it "should revert to the id as the display_name if the dns_name is not supported" do
      server.should_receive(:respond_to?).with(:dns_name).and_return(false)
      server.should_receive(:id).and_return(:id)
      server.display_name.should be :id
    end

  end
end