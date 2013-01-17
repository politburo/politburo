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

  context "#create_ssh_session" do
    let(:ssh) { double('ssh') }
    let(:options) { double('options') }

    it "should use the fog ssh class to create an ssh session" do
      server.should_receive(:requires).with(:public_ip_address, :username)

      server.should_receive(:public_ip_address).and_return(:public_ip_address)
      server.should_receive(:username).and_return(:username)
      server.stub(:private_key).and_return(:private_key)
      server.should_receive(:ssh_port).and_return(:ssh_port)

      Fog::SSH.should_receive(:new).with(:public_ip_address, :username, { key_data: [ :private_key ], port: :ssh_port }).and_return(ssh)

      ssh.should_receive(:create_session).and_return(:session)

      server.create_ssh_session.should be(:session)
    end
  end

end