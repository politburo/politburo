require 'net/ssh'
require 'innertube'

module Politburo
	module Resource
		class Node < Base
			attr_accessor :host
			attr_accessor :user

			attr_accessor :server_creation_overrides

			inherits :user

			requires :parent_resource

			def create_session
				Net::SSH.start(host, user)
			end

      def session_pool
        @session_pool ||= Innertube::Pool.new(  proc { create_session },
                                              proc { |c| c.close })
      end

			def release
				session_pool.each { | session | session.close }
			end

      def context_class
        NodeContext
      end

    end

  end
end

