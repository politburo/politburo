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

			def parent(&block)
				raise "Resource '#{receiver.full_name}' doesn't have a parent" unless receiver.parent_resource
				parent_context = receiver.parent_resource.context

				parent_context.define(&block) if block_given?

				parent_context
			end

      def state(attributes, &block)
        lookup_or_create_resource(::Politburo::Resource::State, attributes, &block)
      end

			def method_missing(method, *args, &block)
				begin
					delegate_call_to_parent_context(self, method, *args, &block)
				rescue => e
					return @receiver.send(method, *args, &block) if @receiver.respond_to?(method)
					if e.is_a?(NoMethodError) 
						raise NoMethodError.new("Could not locate method '#{method}' on context '#{full_name}''s hierarchy, or its receiver.", method)
					else
						raise e
					end
				end
			end

			def delegate_call_to_parent_context(original_context, method, *args, &block)
				return explicit_nouns[method].call(original_context, *args, &block) if responds_to_noun?(method)
				unless receiver.parent_resource.nil?
					return parent.delegate_call_to_parent_context(original_context, method, *args, &block) 
				else
					raise NoMethodError.new("Could not locate method '#{method}' on context hierarchy", method)
				end
			end

			def responds_to_noun?(noun)
				explicit_nouns.include?(noun)
			end

			def type(type_sym, options = {}, &block)
				based_on = options.delete(:based_on)
				raise ":based_on is a required options for context#type." unless based_on
				based_on_class = based_on.is_a?(Symbol) ? types[based_on] : based_on
				
				new_class = Class.new(based_on_class, &block)
				add_noun_and_type(type_sym, new_class)

				new_class
			end

			def add_noun_and_type(type_noun_sym, klass)
				types[type_noun_sym] = klass
				noun(type_noun_sym) { | context, attributes, &block | context.lookup_or_create_resource(klass, attributes, &block) }
			end

			def types
				@types ||= {}
			end

			def depends_on(dependent_context)
				receiver.add_dependency_on(dependent_context.receiver)
				dependent_context
			end

			def containing_node(&block)
			  if receiver.kind_of? Politburo::Resource::Node
			  	define(&block)
			  	return self
			  elsif (receiver.parent_resource)
			  	return parent.containing_node(&block)
				end
				raise "Could not locate containing node before reaching root."
			end

			def lookup(find_attrs, &block)
				context = find_one_by_attributes(find_attrs)
				raise "Could not find resource by attributes: #{find_attrs}." if (context.nil?) 
				context.define(&block) if block_given?
				
				context
			end

			def find_one_by_attributes(find_attrs)
				receivers = receiver.find_all_by_attributes(find_attrs)
				receivers.merge(receiver.parent_resource.find_all_by_attributes(find_attrs)) if (receivers.empty?) and (!receiver.parent_resource.nil?)
				if (receivers.empty?) and (!receiver.parent_resource.nil?)
					receivers.merge(receiver.root.find_all_by_attributes(find_attrs)) 
				end
				return nil if receivers.empty?

				raise "Ambiguous resource for attributes: #{find_attrs}. Found: \"#{receivers.map(&:full_name).join("\", \"")}\"." if (receivers.size > 1) 
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
				raise "No block given for defining a new resource." unless block_given?
				context = new_receiver_class.new(attributes).context

				add_child(context.receiver)
				context.evaluate_implied

				context.define(&block)

				unless (context.receiver.is_a?(Politburo::Resource::State))
					receiver.add_dependency_on(context.receiver)
				end

				context
			end

			def role(role_name, &block)

				if block_given?
					role = Politburo::Resource::Role.new(name: role_name.to_s)
					role.implies = block
					
					add_child(role)
				else
					role_context = lookup_and_define_resource(Politburo::Resource::Role, name: role_name.to_s)
					role = role_context.receiver

					unless receiver.applied_roles.include?(role)
						define(&role_context.receiver.implies)
						receiver.applied_roles << role
					end

					role_context
				end
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

			def evaluate_implied
				receiver.class.implied.each do | implied_proc |
					define(&implied_proc)
				end
			end

			def explicit_nouns
				@explicit_nouns ||= {}
			end

			def noun(noun, &lambda)
				explicit_nouns[noun] = lambda
			end

			protected

		  def validate!()
		    receiver.each { | r | r.validate! }
		  end

			def find_attributes(new_receiver_class, name_or_attributes)
				attributes = name_or_attributes.respond_to?(:keys) ? name_or_attributes : { name: name_or_attributes }
				attributes.merge(:class => lambda { | object, attr, value | object.is_a?(new_receiver_class) } )
			end

			def create_receiver(new_receiver_class, attributes)
				
			end

		end

	end

end