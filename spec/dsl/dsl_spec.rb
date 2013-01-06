describe Politburo::DSL do

  context "#default_plugins" do

    it { Politburo::DSL.default_plugins.should be_a Set }
    
  end

  context "::define" do
    context "unit test" do

      let (:root) { double("root resource") }
      let (:context) { double("root context") }

      before :each do
        Politburo::Resource::Root.stub(:new).with(name: "").and_return(root)
        root.stub(:context).and_return(context)
        root.stub(:apply_plugins)
        context.stub(:define).with("string eval").and_return(root)
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