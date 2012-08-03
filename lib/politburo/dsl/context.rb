module Politburo

	module DSL

		class Context
			attr_reader :receiver

			def initialize(receiver)
				@receiver = receiver
			end

			def define(&block)
				instance_eval &block

				receiver
			end

			alias :evaluate :define

			def environment(attributes, &block)
				define_or_lookup_receiver(::Politburo::Resource::Environment, attributes, &block)
			end

			def node(attributes, &block)
				define_or_lookup_receiver(::Politburo::Resource::Node, attributes, &block)
			end

			def state(state_name)
				Context.new(receiver.state(state_name))
			end

			def depends_on(state)
				receiver.add_dependency_on(state)
			end

			def lookup(find_attrs)
				receivers = receiver.find_all_by_attributes(find_attrs)
				receivers.merge(receiver.parent_resource.find_all_by_attributes(find_attrs)) if (receivers.empty?) and (!receiver.parent_resource.nil?)
				receivers.merge(receiver.root.find_all_by_attributes(find_attrs)) if (receivers.empty?) and (!receiver.parent_resource.nil?)
				raise "Could not find receiver by attributes: #{find_attrs.inspect}." if (receivers.empty?) 
				raise "Ambiguous receiver for attributes: #{find_attrs.inspect}. Founds: #{receivers.inspect}" if (receivers.size > 1) 
				receivers.first				
			end

			private

			def define_or_lookup_receiver(new_receiver_class, attributes, &block)
				if (block_given?)
					# Definition
					define_new_receiver(new_receiver_class, attributes, &block)
				else
					# Lookup
					find_attrs = attributes.merge(:class => new_receiver_class)
					lookup(find_attrs)
				end
			end

			def define_new_receiver(new_receiver_class, attributes, &block)
				new_receiver = new_receiver_class.new(attributes.merge(parent_resource: receiver))
				Context.new(new_receiver).define(&block)

				receiver.add_dependency_on(new_receiver)

				new_receiver
			end

		end

		def self.define(&block)
			root_resource = Politburo::Resource::Base.new(name: "All")
			root_context = Context.new(root_resource)
			root_context.define(&block)
		end
	end

end