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
				@context ||= context_class.new(self)
			end

			def context_class
				Politburo::DSL::Context
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
					raise "#{self} does not have a setter for attribute '#{attr_name}'." unless self.respond_to?(setter_sym)
					self.send(setter_sym, attr_value )
				end
			end

			def validate!
				raise ValidationError.new(self, validation_errors) unless valid?
			end

			module ClassMethods

				def validations
					@validations ||= {}
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

				def inherits(name_sym_)
					name_sym = name_sym_.to_sym

					attr_reader name_sym unless (method_defined?(name_sym))

					original_name_sym = "original_#{name_sym}".to_sym
					alias_method original_name_sym, name_sym

					define_method(name_sym) do
						self.send(original_name_sym) || (parent_resource.nil? ? nil : parent_resource.send(name_sym))
					end

					attr_writer(name_sym)
				end

				def requires(name_sym)
					add_validation(name_sym, lambda do | name_sym, instance | 
						value = nil
						begin
							value = instance.send(name_sym.to_sym)
						rescue => e
							# Any errors will result in value being blank
						ensure
							raise "'#{name_sym.to_s}' is required" if value.nil?
						end
					end
					)
				end

				def explicitly_implied
					@explicitly_implied ||= []
				end

				def implies(&block)
					explicitly_implied << block
				end

				def implied
					implied = []
					implied.push(*superclass.explicitly_implied) if (!superclass.nil?) and (superclass.respond_to?(:explicitly_implied))
					implied.push(*explicitly_implied)

					implied
				end

				private

				def add_validation(name_sym, validation_lambda)
					validations[name_sym.to_sym] ||= []
					validations[name_sym.to_sym] << validation_lambda
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