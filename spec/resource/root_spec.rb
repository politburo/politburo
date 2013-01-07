describe Politburo::Resource::Root do
  let(:root) { Politburo::Resource::Root.new(name: "Root") }

  it { root.should be_a Politburo::Resource::Base }

  it("should have its own context class") { root.context_class.should be Politburo::Resource::RootContext }

  it("should not have a parent resource") { root.parent_resource.should be nil }
  it("should be its own root") { root.root.should be root }

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

  describe Politburo::Resource::RootContext do

    context "#plugin" do

      it "should call find_or_create_resource with the specified plugin class" do
        root.context.should_receive(:find_or_create_resource).with(:class, name: 'class')
        root.context.plugin(class: :class)
      end

    end
  end

end