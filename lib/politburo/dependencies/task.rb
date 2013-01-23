module Politburo
  module Dependencies
    module Task
      include Politburo::Support::HasLogger

      def self.included(base)
        base.extend(ClassMethods)
      end

      def self.states
        [ :unexecuted, :started, :ready_to_meet, :executing, :failed, :satisfied ]
      end

      def retry_timeout
        @retry_timeout ||= 600.0
      end

      def retries
        @retries ||= 3
      end

      def unexecuted?
        state == :unexecuted
      end

      def started?
        state == :started
      end

      def ready_to_meet?
        state == :ready_to_meet
      end

      def executing?
        state == :executing
      end

      def failed?
        state == :failed
      end

      def satisfied?
        state == :satisfied
      end

      def available_for_queueing?
        !in_progress? and (unexecuted? or ready_to_meet? or failed?)
      end

      def in_progress?
        @in_progress ||= false
      end

      def in_progress=(value)
        @in_progress = value
      end

      def state
        @state ||= :unexecuted
      end

      def state=(value)
        raise "Unknown state: #{value.to_s}" unless Task::states.include? value
        logger.debug("Setting state to: #{value.to_s.yellow}")
        @state = value
      end

      def cleanup
        true
      end

      def primary_path
        paths.first
      end

      def paths
        @paths ||= []
      end

      attr_accessor :cause_of_failure

      def unsatisfied_idle_prerequisites
        (prerequisites || []).select(&:available_for_queueing?)
      end

      def all_prerequisites_satisfied?
        (prerequisites || []).all?(&:satisfied?)
      end

      def done?
        satisfied? and all_prerequisites_satisfied?
      end

      def verify_met?(try = 0)
        met?(true)
      end

      def step
        task = self

          begin
            task.logger.debug("Step called! Current state: #{task.state.to_s.yellow}")
            case task.state
            when :unexecuted
              task.logger.debug("Just started!")
              task.state = :started
            when :started
              task.logger.debug("Validating prerequisites before task.met?...")
              raise "Can't check if task was met when it has unsatisfied prerequisites" unless task.all_prerequisites_satisfied?

              task.logger.debug("About to ask met? of the task...")
              if (task.met?) then
                task.state = :satisfied
              else
                task.state = :ready_to_meet
              end
            when :ready_to_meet
              task.logger.debug("Validating prerequisites before task.meet...")
              raise "Can't execute task when it has unsatisfied prerequisites" unless task.all_prerequisites_satisfied?
              task.state = :executing
              task.logger.debug("About to meet the task...")
              if ! Task.wait_for(retry_timeout, retries) { | try | task.logger.debug("Will try to meet the task again (retry ##{try})...") if try > 0; task.meet(try) }
                task.state = :failed
                task.cause_of_failure = RuntimeError.new("Task '#{task.name}' failed as calling #meet() indicated failure by returning nil or false.")
              elsif Task.wait_for(retry_timeout, retries) { | try | task.verify_met?(try) }
                task.state = :satisfied
              else
                task.state = :failed
                task.cause_of_failure = RuntimeError.new("Task '#{task.name}' failed as its criteria hasn't been met after executing.")
              end
              task.logger.debug("About to clean-up task after #meet...")
              task.cleanup
            when :satisfied
              raise "Assertion failed. Task resumed with .step() when already satisfied!"
            when :failed
              raise "Assertion failed. Task resumed with .step() when already failed!"
            end
          rescue => e
            task.state = :failed
            task.cause_of_failure = e
            task.logger.debug("About to clean-up task after an error was raised...")
            task.cleanup
          end

          task
      end

      def self.wait_for(timeout=600, retries=3, interval=1, &block)
        duration = 0
        start = Time.now
        retries_left = retries
        until (duration = Time.now - start) > timeout or (retries_left <= 0) or (success = yield(retries - retries_left))
          retries_left = (retries_left - 1)
          Kernel.sleep(interval.to_f)
        end
        if success
          { :duration => (Time.now - start) }
        else
          false
        end
      end

      def log_formatter
        @log_formatter ||= lambda do |severity, datetime, progname, msg|
          "#{datetime.to_s} #{severity.to_s.colorize( severity_color[severity.to_s.downcase.to_sym])}\t#{self.name.white}\t#{msg}\n"
        end
      end

      module ClassMethods
      end

    end
  end
end
