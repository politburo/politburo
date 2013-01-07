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

				raise "Ambiguous receiver for attributes: #{find_attrs}. Found: \"#{receivers.map(&:name).join("\", \"")}\"." if (receivers.size > 1) 
				receivers.first.context
			end

			def lookup_or_create_resource(new_receiver_class, attributes, &block)
				if block_given?
					create_and_define_resource(new_receiver_class, attributes, &block)
				else
					lookup_and_define_resource(new_receiver_class, attributes, &block)
				end
			end

			def create_and_define_resource(new_receiver_class, attributes, &block)
				context = create_receiver(new_receiver_class, attributes)
				raise "No block given for defining a new receiver." unless block_given?

				context.define(&block)

				depends_on(context)

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
				new_receiver_class.new(attributes.merge(parent_resource: receiver)).context
			end

		end

	end

end