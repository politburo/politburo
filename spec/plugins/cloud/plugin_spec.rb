describe Politburo::Plugins::Cloud::Plugin do
  let(:plugin) { Politburo::Plugins::Cloud::Plugin.new(name: 'test cloud plugin') }

  it { plugin.should be_a Politburo::Plugins::Base }

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
        plugin(class: Politburo::Plugins::Cloud::Plugin) {}
        environment(name: 'an environment', provider: :provider ) { 
          node(name: 'a node', region: 'a region') {} 
        } 
      }
    }

    let(:node) { root.context.lookup(name: 'a node').receiver }
    let(:environment) { root.context.lookup(name: 'an environment').receiver }

    before :each do

    end

    it { environment.should be_a Politburo::Plugins::Cloud::Environment }

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

        it "should have creation and deletion tasks" do
          plugin.apply_to_node(node)
          
          security_group.state(:created).dependencies.should_not be_empty
          security_group.state(:created).tasks.should_not be_empty
          security_group.state(:created).tasks.first.should be_a Politburo::Plugins::Cloud::Tasks::CloudResourceCreateTask
          
          security_group.state(:terminated).dependencies.should_not be_empty
          security_group.state(:terminated).tasks.should_not be_empty
          security_group.state(:terminated).tasks.first.should be_a Politburo::Plugins::Cloud::Tasks::CloudResourceTerminateTask
        end

        it "should set the security group as the default for the node" do
          plugin.apply_to_node(node)

          node.default_security_group.should be security_group
        end
      end

      context "when it doesn't exist" do

        it "when it doesn't exist, it should create it" do
          parent_resource.find_all_by_attributes(security_group_attrs).should be_empty

          plugin.apply_to_node(node)

          parent_resource.find_all_by_attributes(security_group_attrs).should_not be_empty
        end

        it "should have creation and deletion tasks" do
          plugin.apply_to_node(node)

          security_group.state(:created).dependencies.should_not be_empty
          security_group.state(:created).tasks.should_not be_empty
          security_group.state(:created).tasks.first.should be_a Politburo::Plugins::Cloud::Tasks::CloudResourceCreateTask
          
          security_group.state(:terminated).dependencies.should_not be_empty
          security_group.state(:terminated).tasks.should_not be_empty
          security_group.state(:terminated).tasks.first.should be_a Politburo::Plugins::Cloud::Tasks::CloudResourceTerminateTask
        end

      end

    end

    context "key_pair" do
      let(:environment_context) { environment.context }

      let(:key_pair_attrs) { { class: Politburo::Plugins::Cloud::KeyPair, name: "Default Key Pair for a region", region: 'a region' } }

      let(:key_pair) { environment.find_all_by_attributes(key_pair_attrs).first }

      context "when it already exists" do

        before :each do
          environment_context.define do
            key_pair(name: "Default Key Pair for a region", region: 'a region') {}
          end
        end

        it "it should do nothing further" do
          environment.find_all_by_attributes(key_pair_attrs).should_not be_empty

          plugin.apply_to_node(node)

          environment.find_all_by_attributes(key_pair_attrs).should_not be_empty
        end

        it "should have creation only tasks" do
          plugin.apply_to_node(node)
          
          key_pair.state(:created).dependencies.should_not be_empty
          key_pair.state(:created).tasks.should_not be_empty
          key_pair.state(:created).tasks.first.should be_a Politburo::Plugins::Cloud::Tasks::KeyPairCreateTask
          
          key_pair.state(:terminated).tasks.should be_empty
        end

        it "should set the security group as the default for the node" do
          plugin.apply_to_node(node)

          node.key_pair.should be key_pair
        end
      end

      context "when it doesn't exist" do

        it "when it doesn't exist, it should create it" do
          environment.find_all_by_attributes(key_pair_attrs).should be_empty

          plugin.apply_to_node(node)

          environment.find_all_by_attributes(key_pair_attrs).should_not be_empty
        end

        it "should have creation and deletion tasks" do
          plugin.apply_to_node(node)

          key_pair.state(:created).dependencies.should_not be_empty
          key_pair.state(:created).tasks.should_not be_empty
          key_pair.state(:created).tasks.first.should be_a Politburo::Plugins::Cloud::Tasks::KeyPairCreateTask
          
          key_pair.state(:terminated).tasks.should be_empty
        end

      end

    end

  end

end
