# Implementation
require_relative 'cloud/fog_server'
require_relative 'cloud/fog_security_group_extensions'
require_relative 'cloud/fog_ssh_extensions'

require_relative 'cloud/provider'
require_relative 'cloud/aws_provider'
require_relative 'cloud/providers'

# Resources
require_relative 'cloud/base_extensions'
require_relative 'cloud/cloud_node'
require_relative 'cloud/cloud_facet'
require_relative 'cloud/cloud_environment'
require_relative 'cloud/root_context_extensions'
require_relative 'cloud/cloud_resource'
require_relative 'cloud/security_group'
require_relative 'cloud/key_pair'
require_relative 'cloud/tasks'

# Plugin
require_relative 'cloud/plugin'
