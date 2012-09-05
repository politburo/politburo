module Politburo
  module Dependencies
    class Runner
      attr_reader :start_with

      def initialize(*tasks_to_run)
        @start_with = tasks_to_run
      end

      def pick_next_task
        visitor = TaskVisitor.new
        visitor.visit(*start_with)

        visitor.have_no_unsatisfied_dependencies.first
      end

      private 

      class TaskVisitor
        def visit(*tasks)
          tasks.each do | task |
            visited << task
            unsatisfied_idle_prerequisites = task.unsatisfied_idle_prerequisites
            have_no_unsatisfied_dependencies << task if unsatisfied_idle_prerequisites.empty?

            self.visit(*unsatisfied_idle_prerequisites)
          end
        end

        def visited
          @visited ||= Set.new
        end

        def have_no_unsatisfied_dependencies
          @have_no_unsatisfied_dependencies ||= Set.new
        end
      end
    end
  end
end

