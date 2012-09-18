module Politburo
  module Dependencies
    class Runner
      attr_reader :start_with
      attr_reader :fiber_consumer_thread_count

      def initialize(*tasks_to_run)
        @start_with = tasks_to_run
        @fiber_consumer_thread_count = 1
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
          logger.debug("Adding task [#{next_task.name}] to queue.")
          execution_queue.push(next_task.fiber)
        else
          logger.debug("Waiting for tasks to become available...")
          Kernel.sleep(1)
        end
      end

      def run
          logger.debug("Creating consumer threads...")
          fiber_consumer_threads
          logger.debug("Consumer threads created.")

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
        logger.debug("About to pop fiber from queue...")
        next_fiber = execution_queue.pop
        logger.debug("Popped fiber #{next_fiber.inspect}, about to resume...")
        next_fiber.resume 
        logger.debug("Resume returned.")
      end

      def execution_queue
        @execution_queue ||= Queue.new
      end

      def logger
        @logger ||= Logger.new(STDOUT)
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

