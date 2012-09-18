module Politburo
  module Dependencies
    module Task
      def self.included(base)
        base.extend(ClassMethods)
      end

      def self.states
        [ :unexecuted, :queued, :ready_to_meet, :executing, :failed, :satisfied ]
      end

      def unexecuted?
        state == :unexecuted
      end

      def queued?
        state == :queued
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
        !satisfied? && !executing? && !queued?
      end

      def state
        @state ||= :unexecuted
      end

      def state=(value)
        raise "Unknown state: #{value.to_s}" unless Task::states.include? value
        @state = value
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

      def fiber
        @fiber ||= begin
          fiber = Fiber.new() do | task |
            begin
              task.state = :queued
              Fiber.yield # Wait as queued
              raise "Can't check if task was met when it has unsatisfied prerequisites" unless task.all_prerequisites_satisfied?

              if (met?) then
                task.state = :satisfied
              else
                task.state = :ready_to_meet
              end
              Fiber.yield # Wait after checking if met, before execution
              raise "Can't execute task when it has unsatisfied prerequisites" unless task.all_prerequisites_satisfied?
              task.state = :executing
              task.meet
              if (task.met?)
                task.state = :satisfied
              else
                task.state = :failed
                task.cause_of_failure = RuntimeError.new("Task #{task.name} failed as its criteria hasn't been met after executing.")
              end
            rescue => e
              task.state = :failed
              task.cause_of_failure = e
            end
          end

          fiber.resume(self)

          fiber
        end
      end

      module ClassMethods
      end

    end
  end
end
