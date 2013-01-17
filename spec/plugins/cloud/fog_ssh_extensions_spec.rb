describe Politburo::Plugins::Cloud::FogSSHExtensions do 
  let(:klass) { 
    Class.new {
      include Politburo::Plugins::Cloud::FogSSHExtensions

      def initialize()
        @address = :address
        @username = :username
        @options = :options
      end
    }
  }

  let(:ssh) { klass.new() }

  context "#create_session" do

    it "should create a session using the instance variables in the class" do
      Net::SSH.should_receive(:start).with(:address, :username, :options).and_return(:session)

      ssh.create_session.should be :session
    end

  end
end