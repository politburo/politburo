module Politburo
  module Dependencies
    module Task
      def self.included(base)
        base.extend(ClassMethods)
      end

      def self.states
        [ :unexecuted, :ready_to_meet, :failed, :satisfied ]
      end

      def unexecuted?
        state == :unexecuted
      end

      def ready_to_meet?
        state == :ready_to_meet
      end

      def failed?
        state == :failed
      end

      def satisfied?
        state == :satisfied
      end

      def state
        @state ||= :unexecuted
      end

      def state=(value)
        raise "Unknown state: #{value.to_s}" unless Task::states.include? value
        @state = value
      end

      def fiber
        @fiber ||= begin
          fiber = Fiber.new() do | task |
            begin
            Fiber.yield # Wait as unexecuted
            if (met?) then
              task.state = :satisfied
            else
              task.state = :ready_to_meet
            end
            Fiber.yield # Wait after checking if met, before execution
            task.meet
            if (task.met?)
              task.state = :satisfied
            else
              task.state = :failed
            end
            rescue => e
              task.state = :failed
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
