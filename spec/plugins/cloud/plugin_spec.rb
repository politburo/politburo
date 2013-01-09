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
    let(:root) { 
      Politburo::Resource::Root.new(name: "").context.define { 
        environment(name: 'an environment', provider: :provider ) { 
          node(name: 'a node', region: 'a region') {} 
        } 
      }
    }

    let(:node) { root.context.lookup(name: 'a node') }

    it "should add a dependency on a creation task to the create state" do
      plugin.apply_to_node(node)

      node.state(:created).dependencies.should_not be_empty      
      node.state(:created).tasks.should_not be_empty      
      node.state(:created).tasks.first.should be_a Politburo::Plugins::Cloud::Tasks::CreateTask
    end

    it "should add a dependency on a start task to the start state" do
      plugin.apply_to_node(node)

      node.state(:starting).dependencies.should_not be_empty      
      node.state(:starting).tasks.should_not be_empty
      node.state(:starting).tasks.first.should be_a Politburo::Plugins::Cloud::Tasks::StartTask
    end

    it "should add a dependency on a stop task to the stopped state" do
      plugin.apply_to_node(node)

      node.state(:stopped).dependencies.should_not be_empty      
      node.state(:stopped).tasks.should_not be_empty
      node.state(:stopped).tasks.first.should be_a Politburo::Plugins::Cloud::Tasks::StopTask
    end

    it "should add a dependency on a terminate task to the terminated state" do
      plugin.apply_to_node(node)

      node.state(:terminated).dependencies.should_not be_empty      
      node.state(:terminated).tasks.should_not be_empty
      node.state(:terminated).tasks.first.should be_a Politburo::Plugins::Cloud::Tasks::TerminateTask
    end

    context "security_group" do
      let(:parent_resource) { node.parent_resource }
      let(:parent_context) { parent_resource.context }

      let(:security_group_attrs) { { class: Politburo::Plugins::Cloud::SecurityGroup, name: "Default Security Group", region: 'a region' } }

      let(:security_group) { parent_resource.find_all_by_attributes(security_group_attrs).first }

      context "when it already exists" do

        before :each do
          parent_resource.context.define do
            security_group(name: "Default Security Group", region: 'a region') {}
          end
        end

        it "it should do nothing further" do
          parent_resource.find_all_by_attributes(security_group_attrs).should_not be_empty

          plugin.apply_to_node(node)

          parent_resource.find_all_by_attributes(security_group_attrs).should_not be_empty
        end

        it "should have a create task" do
          plugin.apply_to_node(node)
          
          security_group.state(:created).dependencies.should_not be_empty
          security_group.state(:created).tasks.should_not be_empty
          security_group.state(:created).tasks.first.should be_a Politburo::Plugins::Cloud::Tasks::SecurityGroupCreateTask
        end

      end

      context "when it doesn't exist" do

        it "when it doesn't exist, it should create it" do
          parent_resource.find_all_by_attributes(security_group_attrs).should be_empty

          plugin.apply_to_node(node)

          parent_resource.find_all_by_attributes(security_group_attrs).should_not be_empty
        end

        it "should have a create task" do
          plugin.apply_to_node(node)

          security_group.state(:created).dependencies.should_not be_empty
          security_group.state(:created).tasks.should_not be_empty
          security_group.state(:created).tasks.first.should be_a Politburo::Plugins::Cloud::Tasks::SecurityGroupCreateTask
        end

      end



    end

  end

end
