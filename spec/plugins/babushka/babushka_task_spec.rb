describe Politburo::Plugins::Babushka::BabushkaTask do  

  let(:root_definition) do
    Politburo::DSL.define do
      self.cli = :fake_cli

      plugin(class: Politburo::Plugins::Babushka::Plugin) {}
      
      environment(name: "environment") do
        node(name: "node") do
          state(:configured) {
            babushka_task(dep: 'cool-as:cool-dep') {
            }
          }
        end
      end
    end
  end

  let(:node) { root_definition.context.lookup(name: 'node').receiver }
  let(:babushka_task) { root_definition.context.lookup(dep: 'cool-as:cool-dep').receiver }

  let(:install_babushka_task) { node.state(:configured).find_all_by_attributes(name: 'install babushka').first }

  it { babushka_task.should be_a Politburo::Plugins::Babushka::BabushkaTask }

  it "should imply an installation task" do
    install_babushka_task.should_not be_nil
  end

  it "should depend on the installation task" do
    babushka_task.should be_dependent_on install_babushka_task
  end

  it "should have a default name" do
    puts babushka_task.method(:name)
    babushka_task.name.should eq "babushka cool-as:cool-dep"
  end

  context "install babushka task" do

    it "should have a command to install babushka" do
      install_babushka_task.command.should be_a Politburo::Tasks::RemoteCommand
    end

    it "should have a command to test if babushka is installed" do
      install_babushka_task.met_test_command.should be_a Politburo::Tasks::RemoteCommand
    end
  end
end