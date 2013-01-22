describe Politburo::DSL do

  context "::define" do
    context "unit test" do

      let (:root) { double("root resource") }
      let (:context) { double("root context", plugin: true ) }
      let(:plugin_class_one) { double("plugin class 1") }
      let(:plugin_class_two) { double("plugin class 2") }

      before :each do
        Politburo::Resource::Root.stub(:new).with(name: "").and_return(root)
        root.stub(:context).and_return(context)
        root.stub(:apply_plugins)
        context.stub(:define).with("string eval").and_return(root)
        context.stub(:evaluate_implied)
        context.stub(:validate!)
      end

      it "should create a new root resource" do
        Politburo::Resource::Root.should_receive(:new).with(name: "").and_return(root)

        Politburo::DSL.define("string eval") { "a block" }
      end

      it "should create a new root context" do
        root.should_receive(:context).and_return(context)

        Politburo::DSL.define("string eval") { "a block" }
      end

      it "should call define on the root context" do
        context.should_receive(:define).with("string eval").and_return(root)

        Politburo::DSL.define("string eval") { "a block" }
      end

      it "should call evaluate_implied on the root context" do
        context.should_receive(:evaluate_implied)

        Politburo::DSL.define("string eval") { "a block" }
      end

      it "should iterate over plugins and add them to root" do
        context.should_receive(:plugin).with(class: plugin_class_one)
        context.should_receive(:plugin).with(class: plugin_class_two)

        Politburo::DSL.define("string eval", [ plugin_class_one, plugin_class_two ]) { "a block" }
      end

      it "should call apply_plugins on the root resource" do
        root.should_receive(:apply_plugins)

        Politburo::DSL.define("string eval") { "a block" }
      end

      it "should call validate on the root context" do
        context.should_receive(:validate!)

        Politburo::DSL.define("string eval") { "a block" }
      end

    end

  end

end