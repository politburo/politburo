module Politburo
  module Plugins
    module Cloud
      module FogSSHExtensions

        def create_session
          Net::SSH.start(@address, @username, @options)
        end

        def self.included(base)
          base.extend(ClassMethods)
        end

        module ClassMethods
        end

      end
    end
  end
end
