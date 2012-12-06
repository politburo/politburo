require 'net/ssh'

module Politburo
	module Resource
		class Node < Base
			attr_accessor :host
			attr_accessor :user

			inherits :flavor
			inherits :availability_zone

			requires :flavor
			requires :parent_resource

			def initialize(parent_resource)
				super(parent_resource)
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

		end
	end
end

