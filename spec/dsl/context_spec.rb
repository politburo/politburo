require 'politburo'

describe Politburo::DSL::Context do
	let(:resource) { double('resource') }
	let(:context) { Politburo::DSL::Context.new(resource) }
	
	context "#role" do
		let(:role) { double('role', implies: nil) }
		let(:role_context) { double('role context', receiver: role)}

		context "when block is given" do

			before :each do
				Politburo::Resource::Role.stub(:new).with(name: 'master').and_return(role)
				context.stub(:add_child).with(role)
				role.stub(:implies=).with(kind_of(Proc))
			end

			it "should create a new role" do
				Politburo::Resource::Role.should_receive(:new).with(name: 'master').and_return(role)

				context.role(:master) {
					self.do_stuff
				}
			end

			it "should add a new role as child" do
				context.should_receive(:add_child).with(role)

				context.role(:master) {
					self.do_stuff
				}
			end

			it "should assign the content of the block to the role's implies attribute" do
				role.should_receive(:implies=).with(kind_of(Proc))

				context.role(:master) {
					self.do_stuff
				}
			end
		end

		context "when no block is given" do
			let(:applied_roles) { [] }

			before :each do
				context.stub(:lookup_and_define_resource).with(Politburo::Resource::Role, name: 'master').and_return(role_context)
				resource.stub(:applied_roles).and_return(applied_roles)
				applied_roles.stub(:<<).with(role)
			end

			it "should attempt to lookup the role" do
				context.should_receive(:lookup_and_define_resource).with(Politburo::Resource::Role, name: 'master').and_return(role_context)

				context.role(:master)
			end

			context "when the role has not been executed on this resource" do

				let(:proc) { Proc.new { do_stuff } }

				it "should execute the role's implies proc within the resource's context" do
					role.should_receive(:implies).and_return(proc)

					resource.should_receive(:do_stuff)

					context.role(:master)
				end

				it "should add the role to the applied roles of the receiver" do
					applied_roles.should_receive(:<<).with(role)

					context.role(:master)
				end
			end

			context "when the role has already been executed on this resource" do
				let(:proc) { Proc.new { do_stuff } }

				before :each do
					role.stub(:implies).and_return(proc)
				end

				it "should not execute the role definition again" do
					resource.should_receive(:applied_roles).and_return([ role ])
					resource.should_receive(:do_stuff).exactly(1).times

					context.role(:master)
					context.role(:master)
				end

			end
		end

	end
end

describe Politburo::DSL::Context, "roles" do

	let(:root_definition) do
		Politburo::DSL.define do
			self.cli = :fake_cli

			role(:nginx_server) {
				self.description = "#{self.description} nginx_server"
			}
			role(:postgres_client) { 
				self.description = "#{self.description} postgres_client"
			}
			role(:postgres_server) do 
				role(:postgres_client)
				self.description = "#{self.description} postgres_server"
			end
			role(:webnode) do
				role(:nginx_server)
				role(:postgres_client)
				self.description = "#{self.description} webnode"
			end
			
			environment(name: "environment") do
				node(name: "node") {
					role(:postgres_server)
					role(:webnode)
				}
				node(name: "another node") do
					role(:webnode)
				end
			end
		end
	end

	let(:node) { root_definition.find_all_by_attributes(name: 'node').first }
	let(:another_node) { root_definition.find_all_by_attributes(name: "another node").first }

	let(:webnode_role) { root_definition.context.role(:webnode).receiver }
	let(:postgres_client_role) { root_definition.context.role(:postgres_client).receiver }

	it "should locate roles correctly" do
		webnode_role.should be_a Politburo::Resource::Role
	end

	it "should execute the role's content in the context of the node" do
		another_node.description.should include 'webnode'

		another_node.applied_roles.should include webnode_role
	end

	it "should execute any implied roles in the context of the node" do
		node.description.should include 'postgres_client'

		node.applied_roles.should include postgres_client_role
	end

	it "should only execute roles once" do
		node.description.split(/\s/).select { |s| s.eql?('postgres_client') }.should have(1).item
	end
end

describe Politburo::DSL::Context do

	describe "#delegate_call_to_parent_context" do
	  let(:parent) { double("parent", context: parent_context) }
	  let(:resource) { double("resource", parent_resource: parent) }

	  let(:parent_context) { double("parent context") }
	  let(:resource_context) { Politburo::DSL::Context.new(resource) }

    context "when it doesn't exist on the current context" do
      before :each do
        resource_context.should_receive(:responds_to_noun?).with(:do_stuff).and_return(false)
      end

      context "when there is a parent resource" do

	      it "should delegate it up the chain" do
	      	parent_context.should_receive(:delegate_call_to_parent_context).with(:original_context, :do_stuff, :arg1, :arg2).and_return(:result)

	      	resource_context.delegate_call_to_parent_context(:original_context, :do_stuff, :arg1, :arg2).should be :result
	      end

	      it "should not attempt to call it on the receiver" do
	      	parent_context.stub(:delegate_call_to_parent_context).with(:original_context, :do_stuff).and_return(:result)
	        resource.should_not_receive(:do_stuff)

	        resource_context.delegate_call_to_parent_context(:original_context, :do_stuff).should be :result
	      end

	    end

	    context "when there isn't a parent resource" do
	    	before :each do
	    		resource.should_receive(:parent_resource).and_return(nil)
	    	end

	    	it "should throw a NameError" do
	    		lambda { resource_context.delegate_call_to_parent_context(:original_context, :do_stuff) }.should raise_error NoMethodError
	    	end

	    end
    end

    context "when it exists on the current context" do
    	let(:original_context) { "Original context" }

    	it "should call on the current context" do
    		resource_context.noun(:do_stuff) { | context, attributes, &block | context }
    	
    		resource_context.responds_to_noun?(:do_stuff).should be true

    		actual_result = resource_context.delegate_call_to_parent_context(original_context, :do_stuff)
    		raise "Failed, expected '#{original_context}', got '#{actual_result}'" unless actual_result == original_context
    	end
    end
	end

	describe "nouns" do
	  let(:resource) { double("resource") }
	  let(:resource_context) { Politburo::DSL::Context.new(resource) }
	  let(:explicit_nouns) { resource_context.explicit_nouns }


		context "#explicit_nouns" do
			it "should be memoized" do
				resource_context.explicit_nouns.should be explicit_nouns
			end

			it "should be a hash" do
				explicit_nouns.should be_a Hash
			end
		end

		context "#noun" do
			let(:a_lambda) { lambda { do_stuff } }
			
			it "should store the lambda for the explicit noun" do
				resource_context.noun(:noun, &a_lambda)
				explicit_nouns[:noun].should be a_lambda
			end

		end

		context "#responds_to_noun?" do

			context "when noun is defined explicitly" do
				before :each do
					explicit_nouns.should_receive(:include?).with(:noun).and_return(true)
				end

				it "should return true" do
					resource_context.responds_to_noun?(:noun).should be true
				end

			end

			context "when noun is not defined explicitly" do
				before :each do
					explicit_nouns.should_receive(:include?).with(:noun).and_return(false)
				end

				it "should return false" do
					resource_context.responds_to_noun?(:noun).should be false
				end

			end
		end

	end

	describe "#method_missing" do
	  
	  let(:parent) { double("parent", context: parent_context) }
	  let(:resource) { double("resource", parent_resource: parent) }

	  let(:parent_context) { double("parent context") }
	  let(:resource_context) { Politburo::DSL::Context.new(resource) }

	  context "when calling a method which doesn't exist on the current context" do

	    context "when it exists on the receiver" do

	      before :each do
	        resource.should_receive(:respond_to?).with(:do_stuff).and_return(true)
	      end

	      it "should call it" do
	        resource.should_receive(:do_stuff).and_return(:stuff_happened)

	        resource_context.do_stuff.should be :stuff_happened
	      end

	    end

	    context "when it doesn't exist on the current receiver" do

	      before :each do
	        resource.should_receive(:respond_to?).with(:do_stuff).and_return(false)
	        resource_context.stub(:delegate_call_to_parent_context).with(resource_context, :do_stuff).and_return(:result)
	      end

	      it "should not call it" do
	        resource.should_not_receive(:do_stuff)

	        resource_context.do_stuff
	      end

	      it "should delegate to the parent context" do
	        resource_context.should_receive(:delegate_call_to_parent_context).with(resource_context, :do_stuff, :arg1, :arg2).and_return(:result)
	        resource_context.do_stuff(:arg1, :arg2).should be :result
	      end

	    end
	  end
	end

end

describe Politburo::DSL::Context do

	let(:root_definition) do
		Politburo::DSL.define do
			self.cli = :fake_cli
			
			environment(name: "environment") do
				node(name: "node") {}
				node(name: "another node") do
					depends_on node(name: "node").state(:configured)
				end
				node(name: "yet another node") do
					state(:configured) do
						depends_on node("node")

						remote_task(
        			name: 'install babushka',
        			command: 'sudo sh -c "`curl https://babushka.me/up`"', 
        			met_test_command: 'which babushka') {	}
					end
				end
			end

			environment(name: 'another environment') do
				node(name: "a node from another galaxy") {}
			end
		end
	end

	let(:environment) { root_definition.find_all_by_attributes(name: 'environment').first }
	let(:another_environment) { root_definition.find_all_by_attributes(name: 'another environment').first }

	let(:node) { root_definition.find_all_by_attributes(name: 'node').first }
	let(:another_node) { root_definition.find_all_by_attributes(name: "another node").first }
	let(:yet_another_node) { root_definition.find_all_by_attributes(name: "yet another node").first }

	let(:remote_task) { root_definition.find_all_by_attributes(name: "install babushka").first }

	let(:another_environment_node) { another_environment.find_all_by_attributes(class: /Node/).first }
	
	before :each do
		root_definition.should_not be nil
		environment.should_not be nil
		another_environment.should_not be nil
		node.should_not be nil
		another_node.should_not be nil
		yet_another_node.should_not be nil
		remote_task.should_not be nil
		another_environment_node.should_not be nil
	end

	context "::define" do

		context "effects test" do
			it "should allow you to define a resource hierarchy" do
				root_definition.name.should eql("")
				root_definition.children.should_not be_empty
				root_definition.children.should include(environment)
				root_definition.children.should include(another_environment)
			end

			it "defined hierarchy, should define an implicit state dependency" do
				environment.state(:ready).should be_dependent_on node.state(:ready)
				environment.state(:ready).should be_dependent_on another_node.state(:ready)
			end

			it "should allow you to define state dependencies" do
				another_node.state(:ready).should be_dependent_on node.state(:configured)
				yet_another_node.state(:configured).should be_dependent_on node.state(:ready)
			end

			it "should allow you to define execution tasks for states" do
				remote_task.should_not be_nil
				yet_another_node.state(:configured).should be_dependent_on remote_task
			end

		end

	end

	context "instance" do
		let(:receiver) { double("receiver") }
		let(:context) { Politburo::DSL::Context.new(receiver) }

		context "#define" do

				it "should wrap internal errors in a context exception" do
					lambda { context.define { raise "Internal error" } }.should raise_error /.*Internal error.*/
				end

		end

		context "#validate!" do
			let(:fake_resource_a) { double("fake resource a") }
			let(:fake_resource_b) { double("fake resource b") }

	    it "should iterate all resources (depth first) starting with the receiver and call #validate! on each" do
	      receiver.should_receive(:each).and_yield(fake_resource_a).and_yield(fake_resource_b)
	      fake_resource_a.should_receive(:validate!)
	      fake_resource_b.should_receive(:validate!)

	      context.send(:validate!)
	    end

		end

		context "#containing_node" do
			it "should return itself if called on a node" do
				node.context.containing_node.should be node.context
			end

			it "should lookup the context for the node containing the resource" do
				remote_task.context.containing_node.should be yet_another_node.context
			end

			it "should raise an error if no containg node for the resource" do
				lambda { another_environment.context.containing_node }.should raise_error "Could not locate containing node before reaching root."
			end
		end

		context "#lookup" do

			let(:context_for_environment) { environment.context }
			let(:context_for_node) { node.context }

			it "should use find_one_by_attributes" do
				context_for_node.should_receive(:find_one_by_attributes).with(class: Politburo::Resource::Node).and_return(context_for_node)
				context_for_node.lookup(class: Politburo::Resource::Node).receiver.should be node
			end

			it "should lookup in parent's hierarchy next" do
				context_for_node.lookup(name: 'another node').receiver.should be another_node
			end

			it "should travel up to the root if neccessary" do
				context_for_node.lookup(name: 'a node from another galaxy').receiver.should be another_environment_node
			end

			it "should raise error if found none" do
				lambda { context_for_environment.lookup(name: 'Does not exist') }.should raise_error('Could not find resource by attributes: {:name=>"Does not exist"}.')
			end

			it "should evaluate the block in context if block is given" do
				context_for_node.stub(:find_one_by_attributes).with(anything).and_return(context_for_node)
				context_for_node.should_receive(:define).and_yield

				lambda { context_for_node.lookup({ some: 'attributes' }) { raise "this was called" } }.should raise_error "this was called"
			end
		end

		context "#find_one_by_attributes" do

			let(:context_for_environment) { environment.context }
			let(:context_for_node) { node.context }

			it "should lookup first within a resource hierarchy" do
				context_for_node.find_one_by_attributes(class: /Node/).receiver.should be node
			end

			it "should lookup in parent's hierarchy next" do
				context_for_node.find_one_by_attributes(name: 'another node').receiver.should be another_node
			end

			it "should travel up to the root if neccessary" do
				context_for_node.find_one_by_attributes(name: 'a node from another galaxy').receiver.should be another_environment_node
			end

			it "should raise error if found more than one" do
				lambda { context_for_environment.find_one_by_attributes(class: /Node/) }.should raise_error('Ambiguous resource for attributes: {:class=>/Node/}. Found: "environment:node", "environment:another node", "environment:yet another node".')
			end


			it "should return nil if found none" do
				context_for_environment.find_one_by_attributes(name: 'Does not exist').should be nil
			end			
		end

		context "#lookup_or_create_resource" do
			let(:context) { node.context }
			let(:attributes) { { attr: 'value' } }

			before :each do
				context.stub(:lookup_and_define_resource).with(:class, :attributes)
			end

			context "when block is given" do

				context "when direct descendant matching attributes exists" do

					it "should use the block to configure the existing state" do
						context.should_receive(:find_and_define_resource).with(:class, attributes.merge(parent_resource: node)).and_return(:existing_receiver_context)
						context.should_not_receive(:create_and_define_resource)

						context.lookup_or_create_resource(:class, attributes) {}.should be :existing_receiver_context
					end
				end

				context "when no direct descendant with matching attributes exist" do

					it "should attempt to create a new one" do
						context.should_receive(:find_and_define_resource).with(:class, attributes.merge(parent_resource: node)).and_return(nil)
						context.should_not_receive(:lookup_and_define_resource)
						context.should_receive(:create_and_define_resource).with(:class, attributes).and_return(:new_receiver_context)

						context.lookup_or_create_resource(:class, attributes) {}.should be :new_receiver_context
					end
				end

			end

			context "when block is not given" do
				it "should attempt to find an existing receiver" do
					context.should_receive(:lookup_and_define_resource).with(:class, attributes).and_return(:existing_receiver_context)

					context.lookup_or_create_resource(:class, attributes).should be :existing_receiver_context
				end
			end

		end

		context "#create_and_define_resource" do
			let(:context) { node.context }
			let(:new_receiver_class) { double("class", implied: []) }
			let(:new_receiver) { double("new receiver") }
			let(:new_receiver_context) { double("new receiver context", receiver: new_receiver) }

			before :each do
				new_receiver_class.stub(:new).with(:attributes).and_return(new_receiver)
				new_receiver.stub(:context).and_return(new_receiver_context)
				new_receiver_context.stub(:define).and_yield
				new_receiver_context.stub(:evaluate_implied)
				node.stub(:add_child).with(new_receiver)
				node.stub(:add_dependency_on).with(new_receiver)
			end

			it "should create a new receiver" do
				new_receiver_class.should_receive(:new).with(:attributes).and_return(new_receiver)
				new_receiver.should_receive(:context).and_return(new_receiver_context)

				(context.create_and_define_resource(new_receiver_class, :attributes) {}).should be new_receiver_context
			end

			it "should raise an error if no block was given" do
				lambda {context.create_and_define_resource(new_receiver_class, :attributes).should be new_receiver }.should raise_error "No block given for defining a new resource."
			end

			it "should evaluate the implied definition for the context" do
				new_receiver_context.should_receive(:evaluate_implied)

				(context.create_and_define_resource(new_receiver_class, :attributes) { }).should be new_receiver_context
			end

			it "should call define on the context" do
				new_receiver_context.should_receive(:define).and_yield

				(context.create_and_define_resource(new_receiver_class, :attributes) { }).should be new_receiver_context
			end

			it "should add the new receiver as a child" do
				node.should_receive(:add_child).with(new_receiver)

				(context.create_and_define_resource(new_receiver_class, :attributes) {}).should be new_receiver_context
			end

			it "should add the new receiver as a depenency" do
				node.should_receive(:add_dependency_on).with(new_receiver)

				(context.create_and_define_resource(new_receiver_class, :attributes) {}).should be new_receiver_context
			end

		end

		context "#evaluate_implied" do
			let(:receiver) { node }
			let(:context) { receiver.context }

			it "should call define with each of the implied blocks for the resource's class" do
				@flag = false
				receiver.class.should_receive(:implied).and_return([ Proc.new { raise('lambda was called') } ])

				lambda { context.evaluate_implied() }.should raise_error /lambda was called/
			end


		end

		context "#find_and_define_resource" do
			let(:context) { node.context }
			let(:existing_resource) { double("existing resource") }
			let(:existing_resource_context) { double("existing resource context", receiver: existing_resource) }

			before :each do
				context.stub(:find_attributes).with(:class, :attributes).and_return(:find_attrs)
				context.stub(:find_one_by_attributes).with(:find_attrs).and_return(nil)
			end

			it "should use find_attributes to construct the attributes to use for finding the resource" do
				context.should_receive(:find_attributes).with(:class, :attributes).and_return(:find_attrs)

				context.find_and_define_resource(:class, :attributes).should be nil
			end

			it "should attempt to find resource by attributes" do
				context.should_receive(:find_one_by_attributes).with(:find_attrs).and_return(nil)

				context.find_and_define_resource(:class, :attributes).should be nil
			end

			context "when resource is found" do
				before :each do
					context.stub(:find_one_by_attributes).with(:find_attrs).and_return(existing_resource_context)
				end

				it "should call define on its context" do
					existing_resource_context.should_receive(:define).and_yield

					context.find_and_define_resource(:class, :attributes) {} .should be existing_resource_context
				end
			end

		end


		context "#lookup_and_define_resource" do
			let(:context) { node.context }
			let(:existing_resource) { double("existing resource") }
			let(:existing_resource_context) { double("existing resource context", receiver: existing_resource) }

			before :each do
				context.stub(:find_attributes).with(:class, :attributes).and_return(:find_attrs)
				context.stub(:lookup).with(:find_attrs).and_return(existing_resource_context)
			end

			it "should use find_attributes to construct the attributes to use for finding the resource" do
				context.should_receive(:find_attributes).with(:class, :attributes).and_return(:find_attrs)

				context.lookup_and_define_resource(:class, :attributes).should be existing_resource_context
			end

			it "should attempt to find resource by attributes" do
				context.should_receive(:lookup).with(:find_attrs).and_return(existing_resource_context)

				context.lookup_and_define_resource(:class, :attributes).should be existing_resource_context
			end

			context "when resource is found" do

				it "should call define on its context" do
					existing_resource_context.should_receive(:define).and_yield

					context.lookup_and_define_resource(:class, :attributes) {} .should be existing_resource_context
				end
			end

		end

		context "#parent" do
			let(:context) { node.context }
			let(:parent_context) { environment.context }

			it "should return the parent context" do
				context.parent.should be parent_context
			end

			it "should raise an error when the receiver doesn't have a parent" do
				root_definition.should_not be_nil
				lambda { root_definition.context.parent }.should raise_error "Resource '' doesn't have a parent"
			end

			it "should evaulate blocks in the parent context" do
				parent_context.should_receive(:define).and_yield

				context.parent { }
			end
		end

	end
end