module Politburo
  module Dependencies
    class Runner
      attr_reader :start_with
      attr_reader :fiber_consumer_thread_count

      def initialize(*tasks_to_run)
        @start_with = tasks_to_run
        @fiber_consumer_thread_count = 5
      end

      def pick_next_task
        visitor = TaskVisitor.new
        visitor.visit([], *start_with)

        visitor.have_no_unsatisfied_dependencies.first
      end

      def terminate?
        next_task = pick_next_task

        return true if !next_task.nil? and next_task.failed?
        return true if @start_with.all?(&:done?)

        false
      end

      def scheduler_step
        next_task = pick_next_task
        if next_task
          execution_queue.push(next_task.fiber)
        else
          Kernel.sleep(1)
        end
      end

      def run
          until (terminate?) do
            scheduler_step
          end

          fiber_consumer_threads.each(&:exit)
          fiber_consumer_threads.each(&:join)
      end

      def create_fiber_consumer_thread
        Thread.new do 
          while (true) do
            fiber_consumer_step
          end
        end
      end

      def fiber_consumer_threads
        @fiber_consumer_threads ||= Array.new(fiber_consumer_thread_count) do | i | 
          create_fiber_consumer_thread
        end
      end 

      def fiber_consumer_step
        execution_queue.pop.resume
      end

      def execution_queue
        @execution_queue ||= Queue.new
      end

      private 

      class TaskVisitor
        def visit(path, *tasks)
          tasks.each do | task |
            visited.add(task)
            raise "Cyclical dependency detected. Task '#{task.name}' is prerequisite of itself. Cycle: #{(path + [ task ]).map(&:name).join(' -> ')}" if path.include?(task)
            if task.all_prerequisites_satisfied? and task.available_for_queueing?              
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

