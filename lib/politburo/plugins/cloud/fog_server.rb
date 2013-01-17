module Politburo
  module Plugins
    module Cloud
      module Server

        def display_name
          return self.dns_name if self.respond_to?(:dns_name) and self.dns_name
          return self.id
        end

        def create_ssh_session
          require 'net/ssh'
          requires :public_ip_address, :username

          options = Hash.new
          options[:key_data] = [private_key] if private_key
          options[:port] ||= ssh_port
          Fog::SSH.new(public_ip_address, username, options).create_session
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
