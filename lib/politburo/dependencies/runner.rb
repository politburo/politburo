module Politburo
  module Dependencies
    class Runner
      attr_reader :start_with

      def initialize(*tasks_to_run)
        @start_with = tasks_to_run
      end

      def pick_next_task
        visitor = TaskVisitor.new
        visitor.visit([], *start_with)

        visitor.have_no_unsatisfied_dependencies.first
      end

      private 

      class TaskVisitor
        def visit(path, *tasks)
          tasks.each do | task |
            visited.add(task)
            raise "Cyclical dependency detected. Task '#{task.name}' is prerequisite of itself. Cycle: #{(path + [ task ]).map(&:name).join(' -> ')}" if path.include?(task)
            if task.all_prerequisites_satisfied?              
              have_no_unsatisfied_dependencies << task 
            else
              self.visit(path + [ task ], *task.unsatisfied_idle_prerequisites)
            end
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

