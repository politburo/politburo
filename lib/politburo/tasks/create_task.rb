module Politburo
  module Tasks
    class CreateTask < Politburo::Resource::StateTask

      def met?
        resource.cloud_server
      end

      def meet
        resource.cloud_provider.find_or_create_server_for(resource)
      end
    end
  end
end
