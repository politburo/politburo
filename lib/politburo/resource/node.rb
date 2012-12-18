require 'net/ssh'

module Politburo
	module Resource
		class Node < Base
			attr_accessor :host
			attr_accessor :user

			inherits :provider
			inherits :provider_config
			inherits :availability_zone

			requires :provider
			requires :parent_resource

			def initialize(parent_resource)
				super(parent_resource)

				#require 'pry'
				#state(:created).pry
				state(:created).add_dependency_on(Politburo::Tasks::CreateTask.new(name: "Create #{self.full_name}", resource_state: state(:created)))
			end

			def create_session
				Net::SSH.start(host, user)
			end

			def session(create_if_missing = true)
				@session || @session = (create_if_missing ? create_session : nil)
			end

			def release
				session(false).close if session(false)
			end

			def cloud_provider
				Politburo::Resource::Cloud::Providers.for(self)
			end

			def cloud_server
				cloud_provider.find_server_for(self)
			end
			
		end
	end
end

