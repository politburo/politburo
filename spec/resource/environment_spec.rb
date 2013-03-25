require 'politburo'

describe Politburo::Resource::Environment do

	let(:parent_resource) { Politburo::Resource::Base.new(name: 'Parent resource') }
	let(:environment) { Politburo::Resource::Environment.new(name: "Environment resource") }

  before :each do
    parent_resource.add_child(environment)
  end

	it "should have all the default states" do
		parent_resource.states.each do | state | 
			state = environment.state(state.name)
			state.should_not be_nil
		end
	end

  context "#private_keys_path" do
    let(:private_keys_path) { double("private keys path") }
    let(:cli) { double("CLI") }
    let(:root) { double("root") }

    it "should default to getting it from the CLI" do
      environment.should_receive(:root).and_return(root)
      root.should_receive(:cli).and_return(cli)
      cli.should_receive(:private_keys_path).and_return(private_keys_path)

      environment.private_keys_path.should be private_keys_path
    end

  end  

end
