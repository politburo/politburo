module Politburo

	module DSL

		class ContextException < Exception
			def initialize(msg = nil, cause = nil)
				super(msg)
				@cause = cause
			end

			attr_reader :cause
		end

		class Context
			attr_reader :receiver

			def initialize(receiver)
				@receiver = receiver
			end

			def define(definition = nil, &block)
				instance_eval(definition) if definition
				instance_eval(&block) if block_given?

				receiver
			rescue => e
				raise ContextException.new("Error while evaluating DSL context. Underlying error is: #{e}\n\t#{e.backtrace.join("\n\t")}", e)
			end

			alias :evaluate :define

      def state(attributes, &block)
        lookup_or_create_resource(::Politburo::Resource::State, attributes, &block)
      end

			def method_missing(method, *args)
				@receiver.send(method, *args)
			end

			def depends_on(dependent_context)
				receiver.add_dependency_on(dependent_context.receiver)
				dependent_context
			end

			def lookup(find_attrs)
				context = find_one_by_attributes(find_attrs)
				raise "Could not find receiver by attributes: #{find_attrs}." if (context.nil?) 
				context
			end

			def find_one_by_attributes(find_attrs)
				receivers = receiver.find_all_by_attributes(find_attrs)
				receivers.merge(receiver.parent_resource.find_all_by_attributes(find_attrs)) if (receivers.empty?) and (!receiver.parent_resource.nil?)
				if (receivers.empty?) and (!receiver.parent_resource.nil?)
					receivers.merge(receiver.root.find_all_by_attributes(find_attrs)) 
				end
				return nil if receivers.empty?

				raise "Ambiguous receiver for attributes: #{find_attrs}. Found: \"#{receivers.map(&:full_name).join("\", \"")}\"." if (receivers.size > 1) 
				receivers.first.context
			end

			def lookup_or_create_resource(new_receiver_class, name_or_attributes, &block)
				attributes = name_or_attributes.respond_to?(:keys) ? name_or_attributes : { name: name_or_attributes }
				if block_given?
					find_and_define_resource(new_receiver_class, attributes.merge(parent_resource: receiver), &block) || create_and_define_resource(new_receiver_class, attributes, &block)
				else
					lookup_and_define_resource(new_receiver_class, attributes, &block)
				end
			end

			def create_and_define_resource(new_receiver_class, attributes, &block)
				raise "No block given for defining a new receiver." unless block_given?
				context = new_receiver_class.new(attributes).context

				add_child(context.receiver)
				new_receiver_class.implied.each do | implied_proc |
					context.define(&implied_proc)
				end

				context.define(&block)

				unless (context.receiver.is_a?(Politburo::Resource::State))
					receiver.add_dependency_on(context.receiver)
				end

				context
			end

			def find_and_define_resource(new_receiver_class, name_or_attributes, &block)
				context = find_one_by_attributes(find_attributes(new_receiver_class, name_or_attributes))
				return nil if context.nil?

				if (block_given?)
					context.define(&block)
				end

				context				
			end

			def lookup_and_define_resource(new_receiver_class, name_or_attributes, &block)
				context = lookup(find_attributes(new_receiver_class, name_or_attributes))
				if (block_given?)
					context.define(&block)
				end

				context
			end

			protected

		  def validate!()
		    receiver.each { | r | r.validate! }
		  end

			def find_attributes(new_receiver_class, name_or_attributes)
				attributes = name_or_attributes.respond_to?(:keys) ? name_or_attributes : { name: name_or_attributes }
				attributes.merge(:class => new_receiver_class)
			end

			def create_receiver(new_receiver_class, attributes)
				
			end

		end

	end

end