 module Politburo

	module DSL

		module DslDefined
			include Politburo::Support::AccessorWithDefault
			include Politburo::Support::HasLogger

      attr_accessor_with_default(:log_level) { ((!parent_resource.nil?) and parent_resource.log_level) || Logger::INFO }
      attr_accessor_with_default(:logger_output) { ((!parent_resource.nil?) and parent_resource.logger_output) || $stdout } 

			def self.included(base)
				base.extend(ClassMethods)
			end

			def context
				@context ||= Politburo::DSL::Context.new(self)
			end

			def validation_errors
				self.class.validation_errors_for(self)
			end

			def valid?
				validation_errors.empty?
			end

			def [](attribute_name)
				attribute_name_sym = attribute_name.to_sym
				return nil unless self.respond_to?(attribute_name_sym)
				self.send(attribute_name_sym)
			end

			def update_attributes(attributes)
				attributes.each_pair do | attr_name, attr_value |
					setter_sym = "#{attr_name.to_s}=".to_sym
					raise "parent_resource is not assignable from initializer. Use parent's add_child instead." if setter_sym == :parent_resource=
					raise "#{self} does not have a setter for attribute '#{attr_name}'." unless self.respond_to?(setter_sym)
					self.send(setter_sym, attr_value )
				end
			end

			def validate!
				raise ValidationError.new(self, validation_errors) unless valid?
			end

			module ClassMethods

				def explicit_validations
					@explicit_validations ||= {}
				end

				def validations
					validations = {}

					klass = self
					until (klass.nil?)
						if klass.respond_to?(:explicit_validations)
							klass.explicit_validations.each_pair do | attr, validations_for_attr |
								validations[attr] = validations_for_attr + (validations[attr] || [])
							end
						end
						klass = klass.superclass
					end

					validations
				end

				def validation_errors_for(instance)
					errors = {}

					validations.each_pair do | name_sym, validations_for_attr | 
						validation_errors_for_attr = validations_for_attr.map do | validation |
							begin
								validation.call(name_sym, instance)
								nil
							rescue => e
								e
							end
						end.compact

						errors[name_sym] = validation_errors_for_attr unless validation_errors_for_attr.empty?
					end

					errors
				end

				def inherits(name)
					attr_with_default(name) { (parent_resource.nil? ? nil : parent_resource.send(name.to_sym)) }
				end

				def requires(name_sym)
					validates(name_sym) do | name_sym, instance | 
						value = nil
						begin
							value = instance.send(name_sym.to_sym)
							value
						rescue => e
							# Any errors will result in value being blank
						ensure
							raise "'#{name_sym.to_s}' is required" if value.nil?
						end
					end
					
				end

				def attr_with_default(name, &default_value)
					raise "Block is required for default value" unless block_given?

					name_sym = name.to_sym

					attr_reader name_sym unless (method_defined?(name_sym))
					attr_writer name_sym unless (method_defined?("#{name_sym}=".to_sym))

					original_name_sym = "original_#{name_sym}".to_sym
					alias_method original_name_sym, name_sym

					define_method(name_sym) do
						self.send(original_name_sym) || self.instance_eval(&default_value)
					end

				end

				def explicitly_implied
					@explicitly_implied ||= []
				end

				def implies(&block)
					explicitly_implied << block
				end

				def implied
					implied = []
					klass = self
					until (klass.nil?)
						implied.insert(0, *klass.explicitly_implied) if klass.respond_to?(:explicitly_implied)
						klass = klass.superclass
					end

					implied
				end

				def validates(name_sym, &validation_lambda)
					explicit_validations[name_sym.to_sym] ||= []
					explicit_validations[name_sym.to_sym] << validation_lambda
				end
			end

			class ValidationError < Exception
				def initialize(invalid_object, validation_errors)
					super("Validation error(s): #{validation_errors.each_pair.map { |k, v| v.map(&:message) } .flatten.join(", ")}")

					@invalid_object = invalid_object
					@validation_errors = validation_errors
				end
			end

		end

	end

end