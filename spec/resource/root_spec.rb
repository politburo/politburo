describe Politburo::Resource::Root do
  let(:root) { Politburo::Resource::Root.new(name: "Root") }

  it { root.should be_a Politburo::Resource::Base }

  it("should not have a parent resource") { root.parent_resource.should be nil }
  it("should be its own root") { root.root.should be root }

  context "#context" do

    it "should have the receiver set correctly" do
      root.context.receiver.should be root
    end
    
  end
  
  context "#cli" do
    it("should be an attribute") do
      root.cli = :cli
      root.cli.should be :cli
    end

    it "should be required" do
      root.should_not be_valid

      root.cli = :cli

      root.should be_valid
    end
  end

  context "#apply_plugins" do
    let(:plugin_one) { double("plugin 1") }
    let(:plugin_two) { double("plugin 2") }

    it "should iterate over every plugin and call its apply method" do
      root.should_receive(:find_all_by_attributes).with(kind_of(Hash)).and_return([ plugin_one, plugin_two ])
      plugin_one.should_receive(:apply)
      plugin_two.should_receive(:apply)

      root.apply_plugins
    end

  end

  describe "#context" do

    describe "default nouns" do

      context "#plugin" do
        let(:receiver) { double("receiver") }
        let(:context) { root.context }
        let(:plugin) { double("plugin") }
        let(:plugin_context) { double("plugin context", receiver: plugin) }

        before :each do
          context.stub(:lookup_or_create_resource).with(:class, name: 'class').and_return(plugin_context)

          plugin.stub(:load).with(context)
        end

        it "should call lookup_or_create_resource with the specified plugin class" do
          context.should_receive(:lookup_or_create_resource).with(:class, name: 'class').and_return(plugin_context)

          context.plugin(class: :class)
        end

        it "should load the plugin" do
          plugin_context.should_receive(:receiver).and_return(plugin)
          plugin.should_receive(:load).with(context)

          context.plugin(class: :class)
        end

        it "should return the plugin context" do
          context.plugin(class: :class).should be plugin_context
        end

      end
    end
  end

end