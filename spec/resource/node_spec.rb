require 'politburo'

describe Politburo::Resource::Node do

	let(:parent_resource) { Politburo::Resource::Base.new(name: "Parent resource") }
	let(:node) do 
		Politburo::Resource::Node.new(parent_resource: parent_resource, name: "Node resource")
	end

  context "#initialize" do


    it "should add a dependency on a creation task to the create state" do
      node.state(:created).dependencies.should_not be_empty      
      node.state(:created).tasks.should_not be_empty      
      node.state(:created).tasks.first.should be_a Politburo::Tasks::CreateTask
    end

    it "should add a dependency on a start task to the start state" do
      node.state(:starting).dependencies.should_not be_empty      
      node.state(:starting).tasks.should_not be_empty
      node.state(:starting).tasks.first.should be_a Politburo::Tasks::StartTask
    end

    it "should add a dependency on a stop task to the stopped state" do
      node.state(:stopped).dependencies.should_not be_empty      
      node.state(:stopped).tasks.should_not be_empty
      node.state(:stopped).tasks.first.should be_a Politburo::Tasks::StopTask
    end

    it "should add a dependency on a terminate task to the terminated state" do
      node.state(:terminated).dependencies.should_not be_empty      
      node.state(:terminated).tasks.should_not be_empty
      node.state(:terminated).tasks.first.should be_a Politburo::Tasks::TerminateTask
    end
  end

  context "#provider" do

    it "should inherit provider" do
      parent_resource.should_receive(:provider).and_return(:simple)

      node.provider.should be :simple
    end

  	it "should require a provider" do
      parent_resource.should_receive(:provider).and_return(nil)
  		node.provider = nil
  		node.should_not be_valid
  	end

  end

  context "#availability_zone" do

    it "should inherit availability_zone" do
      parent_resource.should_receive(:availability_zone).and_return(:us_west_1)

      node.availability_zone.should be :us_west_1
    end

  end

  context "#provider_config" do

    it "should inherit provider_config" do
      parent_resource.should_receive(:provider_config).and_return(:config)

      node.provider_config.should be :config
    end

  end

  context "#cloud_provider" do

    it "should use the Provider class to ask for the provider from the pool, based on the type and config" do
      Politburo::Resource::Cloud::Providers.should_receive(:for).with(node).and_return(:cloud_provider)

      node.cloud_provider.should be :cloud_provider
    end
  end
  context "#cloud_server" do
    let(:cloud_provider) { double("fake cloud provider") }

    before :each do
      node.should_receive(:cloud_provider).and_return(cloud_provider)
    end

    it "should use the cloud_provider to ask for the server for this node" do
      cloud_provider.should_receive(:find_server_for).with(node).and_return(:cloud_server)

      node.cloud_server.should be :cloud_server
    end
  end

  context "#session" do
    before :each do
      node.stub(:create_session).and_return(double("a session"))
    end

    context "with no existing session" do
      it "it should create one if create_if_missing is true" do
        node.should_receive(:create_session).and_return(double("a session"))
        node.session.should_not be_nil
      end

      it "it should not create one, and return nil if create_if_missing is false" do
        node.session(false).should be_nil
      end
    end

    context "with existing session" do
      let(:existing_session) { node.session }

      it "should return the same session" do
        node.session.should be existing_session
      end
    end
  end

  context "#release" do

    context "with no existing session" do
      it "should release the session if it exists" do
        node.should_receive(:session).with(false).and_return(nil)

        node.release
      end
    end

    context "with existing session" do
      let(:fake_session) { double("a fake session") }

      it "should release the session if it exists" do
        node.should_receive(:session).with(false).at_least(2).times.and_return(fake_session)
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
