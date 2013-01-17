# Used internally by RemoteTask and sublcasses
module Politburo
  module Tasks

    class RemoteCommand
      attr_accessor :command
      attr_accessor :execution_output_match_pattern
      attr_reader   :execution_result

      attr_reader   :logger

      attr_writer   :use_tty

      def initialize(command, logger, execution_output_match_pattern = nil, &validate_success_block)
        @command = command
        @logger = logger
        @execution_output_match_pattern = execution_output_match_pattern

        @validate_success_block = validate_success_block if block_given?
        @execution_result = nil
      end

      def to_s
        command
      end

      def use_tty
        @use_tty ||= false
      end

      def self.unix_command(unix_command, logger, execution_output_match_pattern = nil)
        self.new(unix_command.to_s, logger, execution_output_match_pattern)
      end

      def self.repack(command_obj_or_string, logger, execution_output_match_pattern = nil)
        command_obj_or_string.kind_of?(Politburo::Tasks::RemoteCommand) ? command_obj_or_string : Politburo::Tasks::RemoteCommand.unix_command(command_obj_or_string.to_s, logger, execution_output_match_pattern)
      end

      def execute(channel) 
        exec_result = {}

        if (use_tty) 
          channel.request_pty do | channel, success | 
            raise "Failed to get interactive shell (pty) on SSH session." unless success
            exec_result = execute_on_channel(channel)
          end  
        else
          exec_result = execute_on_channel(channel)
        end

        channel.wait

        @execution_result = exec_result
        if (execution_output_match_pattern) 
          match_data = execution_output_match_pattern.match(captured_output.string)
          @execution_result = @execution_result.merge(match_data ? Hash[ match_data.names.map(&:to_sym).zip( match_data.captures ) ] : {})
        end

        return @execution_result if (@execution_result and validate_success_block.call(self, execution_result))
        nil
      end

      def captured_output
        @captured_output ||= StringIO.new
      end

      def validate_success_block
        @validate_success_block ||= Proc.new { | remote_command, execution_result | execution_result[:exit_status] == 0 }
      end

      private

      def execute_on_channel(ch)
        exec_result = {}
        ch.exec command do | ch, success |
          raise "Could not execute command '#{command}'." unless success

          # "on_data" is called when the process writes something to stdout
          ch.on_data do | c, data |
            captured_output.print(data)
            data.split(/\n/).each { | line | logger.info(line) }
          end

          # "on_extended_data" is called when the process writes something to stderr
          ch.on_extended_data do | c, type, data |
            captured_output.print(data)
            data.split(/\n/).each { | line | logger.error(line) }
          end

          ch.on_request("exit-status") do | ch, data |
            exec_result[:exit_status] = data.read_long
          end

          ch.on_request("exit-signal") do | ch, data |
            exec_result[:exit_signal] = data.read_long
          end

          ch.on_close { }
        end

        exec_result
      end

    end
  end
end
