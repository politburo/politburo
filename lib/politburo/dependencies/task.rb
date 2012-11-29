module Politburo
  module Dependencies
    module Task
      def self.included(base)
        base.extend(ClassMethods)
      end

      def self.states
        [ :unexecuted, :started, :ready_to_meet, :executing, :failed, :satisfied ]
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
              if (met?) then
                task.state = :satisfied
              else
                task.state = :ready_to_meet
              end
            when :ready_to_meet
              task.logger.debug("Validating prerequisites before task.meet...")
              raise "Can't execute task when it has unsatisfied prerequisites" unless task.all_prerequisites_satisfied?
              task.state = :executing
              task.logger.debug("About to meet the task...")
              if !task.meet
                task.state = :failed
                task.cause_of_failure = RuntimeError.new("Task '#{task.name}' failed as calling #meet() indicated failure by returning nil or false.")
              elsif (task.met?)
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

      def log_format(severity, datetime, progname, msg)
        "#{datetime.to_s} #{severity.to_s.colorize( severity_color[severity.to_s.downcase.to_sym])}\t#{self.name.white}\t#{msg}\n"
      end

      def logger
        @logger ||= begin 
          logger = Logger.new($stdout)
          task = self
          logger.level = Logger::INFO
          logger.formatter = proc do |severity, datetime, progname, msg|
            task.log_format(severity, datetime, progname, msg)
          end
          logger
        end
      end

      def severity_color()
        {
          debug: 37,
          info: 36,
          warn: 33,
          error: 31,
        }
      end

      module ClassMethods
      end

    end
  end
end
