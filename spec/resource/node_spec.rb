require 'politburo'

describe Politburo::Resource::Node do

	let(:parent_resource) { Politburo::Resource::Base.new(name: "Parent resource") }
	let(:node) { Politburo::Resource::Node.new(name: "Node resource") }

  before :each do
    parent_resource.add_child(node)
  end

  context "#user" do

    it "should inherit user" do
      parent_resource.should_receive(:user).and_return(:username)

      node.user.should be :username
    end

  end

  context "#session_pool" do
    let(:session_pool) { node.session_pool }

    it "should memoise a connection pool" do
      node.session_pool.should be_a Innertube::Pool
      node.session_pool.should be session_pool
    end
  end

  context "#release" do
    let(:fake_session) { double('fake session') }
    let(:session_pool) { node.session_pool }

    context "with existing sessions" do

      before :each do
        node.should_receive(:create_session).and_return(fake_session)

        node.session_pool.take { }
      end

      it "should iterate over sessions and close them" do
        fake_session.should_receive(:close)

        node.release
      end

    end

  end

  context "#create_session" do
    it "should provide a connection to the node" do
      node.should_receive(:host).and_return(:host)
      node.should_receive(:user).and_return(:user)
      Net::SSH.should_receive(:start).with(:host, :user).and_return(:session)

      session = node.create_session

      session.should_not be_nil
      session.should be :session
    end
  end

end
