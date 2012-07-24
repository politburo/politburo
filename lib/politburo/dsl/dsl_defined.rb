module Politburo

	module DSL

		module DslDefined
			def self.included(base)
				base.extend(ClassMethods)
			end

			def validation_errors
				self.class.validation_errors_for(self)
			end

			def valid?
				validation_errors.empty?
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

				def requires(name_sym)
					add_validation(name_sym, lambda do | name_sym, instance | 
						value = nil
						begin
							value = instance.send(name_sym.to_sym)
						rescue => e
							# Any errors will result in value being blank
						ensure
							raise "'#{name_sym.to_s}' is required." if value.nil?
						end
					end
					)
				end

				private

				def add_validation(name_sym, validation_lambda)
					validations[name_sym.to_sym] ||= []
					validations[name_sym.to_sym] << validation_lambda
				end
			end

		end

	end

end