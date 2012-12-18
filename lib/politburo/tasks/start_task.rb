module Politburo
  module Tasks
    class StartTask < Politburo::Resource::StateTask

      def met?
        resource.cloud_server and resource.cloud_server.ready?
      end

    end
  end
end
