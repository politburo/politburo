module Politburo

	module DSL

		class Context
			attr_reader :resource

			def initialize(resource)
				@resource = resource
			end

			def define(&block)
				instance_eval &block

				resource
			end

			alias :evaluate :define

			def environment(opts, &block)
				define_or_lookup_resource(::Politburo::Resource::Environment, opts, &block)
			end

			def node(opts, &block)
				define_or_lookup_resource(::Politburo::Resource::Node, opts, &block)
			end

			private

			def define_or_lookup_resource(new_resource_class, opts, &block)
				if (block_given?)
					# Definition
					define_new_resource(new_resource_class, opts, &block)
				else
					# Lookup
					resources = resource.root.find_all_by_attributes(opts.merge(:type => new_resource_class.to_s))
					raise "Could not find resource by attributes: #{attributes.options}." if (resources.empty?) 
					raise "Ambiguous resource for attributes: #{attributes.options}. Founds: #{resources.inspect}" if (resources.size > 1) 
					resources.first
				end
			end

			def define_new_resource(new_resource_class, opts, &block)
				new_resource = new_resource_class.new(resource)

				assign_options(new_resource, opts)

				Context.new(new_resource).define(&block)

				new_resource
			end

			def assign_options(resource, opts)
				opts.each_pair do | attr_name, attr_value |
					resource.send("#{attr_name.to_s}=".to_sym, [ attr_value ])
				end
			end
		end


		def self.define(&block)
			root_resource = Politburo::Resource::Base.new()
			root_resource.name = "All"

			root_context = Context.new(root_resource)
			root_context.define(&block)
		end
	end

end