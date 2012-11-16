# Used internally by RemoteTask and sublcasses
module Politburo
  module Tasks

    class RemoteCommand
      attr_accessor :command
      attr_accessor :execution_output_match_pattern
      attr_reader   :execution_result

      attr_reader   :stdin, :stdout, :stderr

      def initialize(command, execution_output_match_pattern, stdin = STDIN, stdout = STDOUT, stderr = STDERR, &validate_success_block)
        @command = command
        @execution_output_match_pattern = execution_output_match_pattern

        @stdin = stdin
        @stdout = stdout
        @stderr = stderr

        @validate_success_block = validate_success_block if block_given?
        @execution_result = nil
      end

      def to_s
        command
      end

      def self.unix_command(unix_command, stdin = STDIN, stdout = STDOUT, stderr = STDERR)
        self.new("#{unix_command}; echo $?", /^(?<exit_code>\d*)$[^$]?\z/, stdin, stdout, stderr)
      end

      def execute(channel) 
        channel.exec command do |ch, success|
          raise "Could not execute command '#{command}'." unless success

          # "on_data" is called when the process writes something to stdout
          ch.on_data do |c, data|
            captured_output.print data
            stdout.print data
          end

          # "on_extended_data" is called when the process writes something to stderr
          ch.on_extended_data do |c, type, data|
            captured_output.print data
            stderr.print data
          end

          ch.on_close { }
        end        

        channel.wait

        match_data = execution_output_match_pattern.match(captured_output.string)

        @execution_result = match_data ? Hash[ match_data.names.map(&:to_sym).zip( match_data.captures ) ] : nil

        return @execution_result if (@execution_result and validate_success_block.call(self, execution_result))
        nil
      end

      def captured_output
        @captured_output ||= StringIO.new
      end

      def validate_success_block
        @validate_success_block ||= Proc.new { | remote_command, execution_result | execution_result[:exit_code] == "0" }
      end

    end
  end
end
