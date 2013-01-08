describe Politburo::Plugins::Cloud::Plugin do
  let(:plugin) { Politburo::Plugins::Cloud::Plugin.new(name: 'test cloud plugin') }

  it { plugin.should be_a Politburo::Plugins::Base }

  it "should add itself to the default plugins" do
    Politburo::DSL.default_plugins.should include Politburo::Plugins::Cloud::Plugin
  end

  context "#apply" do
    let (:root) { double("root") }
    let (:node) { double("a node") }
    let (:nodes) { [ node ]}

    it "should iterate over all nodes and add the cloud tasks to them" do
      plugin.should_receive(:root).and_return(root)
      root.should_receive(:select).and_return(nodes)
      plugin.should_receive(:apply_to_node).with(node)

      plugin.apply
    end

  end

  context "#apply_to_node" do
    let(:node) { Politburo::Resource::Node.new(name: 'test node') }

    it "should add a dependency on a creation task to the create state" do
      plugin.apply_to_node(node)

      node.state(:created).dependencies.should_not be_empty      
      node.state(:created).tasks.should_not be_empty      
      node.state(:created).tasks.first.should be_a Politburo::Tasks::CreateTask
    end

    it "should add a dependency on a start task to the start state" do
      plugin.apply_to_node(node)

      node.state(:starting).dependencies.should_not be_empty      
      node.state(:starting).tasks.should_not be_empty
      node.state(:starting).tasks.first.should be_a Politburo::Tasks::StartTask
    end

    it "should add a dependency on a stop task to the stopped state" do
      plugin.apply_to_node(node)

      node.state(:stopped).dependencies.should_not be_empty      
      node.state(:stopped).tasks.should_not be_empty
      node.state(:stopped).tasks.first.should be_a Politburo::Tasks::StopTask
    end

    it "should add a dependency on a terminate task to the terminated state" do
      plugin.apply_to_node(node)

      node.state(:terminated).dependencies.should_not be_empty      
      node.state(:terminated).tasks.should_not be_empty
      node.state(:terminated).tasks.first.should be_a Politburo::Tasks::TerminateTask
    end

    context "security_group" do
      let(:parent_resource) { double("parent resource") }
      let(:context) { node.context }

      let(:security_group_attrs) { { class: Politburo::Plugins::Cloud::SecurityGroup, name: "Default Security Group", region: node.region } }
      let(:security_group) { double(security_group_attrs) }

      before :each do
        node.stub(:parent_resource).and_return(parent_resource)
        node.stub(:region).and_return(:region)

        parent_resource.stub(:find_all_by_attributes).with(security_group_attrs).and_return([ security_group ])
      end

      it "should attempt to find a matching security group" do
        parent_resource.should_receive(:find_all_by_attributes).with(security_group_attrs).and_return([ security_group ])

        plugin.apply_to_node(node)
      end

      it "when it already exists, it should do nothing further" do
        context.should_not_receive(:security_group)

        plugin.apply_to_node(node)
      end

      it "when it doesn't exist, it should create it" do
        parent_resource.should_receive(:find_all_by_attributes).with(security_group_attrs).and_return([])
        context.should_receive(:security_group).with(name: "Default Security Group", region: node.region)

        plugin.apply_to_node(node)
      end

    end

  end

end
