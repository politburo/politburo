 module Politburo

	module DSL

		module DslDefined
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

					define_method(name_sym) do
						instance_variable_get("@#{name_sym}".to_sym) || parent_resource.send(name_sym)
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

				def attr_reader_with_default(name_sym_, &block)
					raise "attr_reader_with_default requires a block that initializes the default value." unless block_given?
					name_sym = name_sym_.to_sym

					value_proc = block
					define_method(name_sym) do
						instance_variable_get("@#{name_sym}".to_sym) || value_proc.call
					end
				end

				def attr_accessor_with_default(name_sym, &block)
					attr_reader_with_default(name_sym, &block)
					attr_writer(name_sym)
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