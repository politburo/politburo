require 'net/ssh'

module Politburo
	module Resource
		class Node < Base
			attr_accessor :host
			attr_accessor :user

			attr_accessor :server_creation_overrides

			inherits :user

			requires :parent_resource

			def initialize(parent_resource)
				super(parent_resource)

				#require 'pry'
				#state(:created).pry
				state(:created).add_dependency_on(Politburo::Tasks::CreateTask.new(name: "Create server", resource_state: state(:created)))
				state(:starting).add_dependency_on(Politburo::Tasks::StartTask.new(name: "Start server", resource_state: state(:starting)))
				state(:stopped).add_dependency_on(Politburo::Tasks::StopTask.new(name: "Stop server", resource_state: state(:stopped)))
				state(:terminated).add_dependency_on(Politburo::Tasks::TerminateTask.new(name: "Terminate server", resource_state: state(:terminated)))
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

      def context_class
        NodeContext
      end

    end

    class NodeContext < Politburo::Resource::FacetContext
    end

  end
end

