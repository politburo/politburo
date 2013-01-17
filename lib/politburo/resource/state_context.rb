module Politburo
  module Resource

    class StateContext < Politburo::Resource::EnvironmentContext

      def remote_task(attributes, &block)
        lookup_or_create_resource(::Politburo::Tasks::RemoteTask, attributes, &block)
      end

    end

  end
end