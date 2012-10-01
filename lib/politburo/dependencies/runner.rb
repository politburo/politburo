module Politburo
  module Dependencies
    class Runner
      attr_reader :start_with
      attr_reader :task_consumer_thread_count

      def initialize(*tasks_to_run)
        @start_with = tasks_to_run
        @task_consumer_thread_count = 5
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

      def clear_progress_flag_on_done_tasks
        until (done_tasks_queue.empty?)
          done_tasks_queue.pop.in_progress = false
        end
      end

      def scheduler_step
        clear_progress_flag_on_done_tasks

        next_task = pick_next_task
        if next_task and !next_task.failed?
          logger.debug("Adding task '#{next_task.name}' to queue.")
          raise "Assertion failed. Task '#{next_task.name}' provided, but is not available for queueing! (State: #{next_task.state})" unless next_task.available_for_queueing?
          next_task.step if next_task.unexecuted?
          next_task.in_progress = true
          execution_queue.push(next_task)
        else
          logger.debug("Waiting for tasks to become available...")
          Kernel.sleep(0.01)
        end
      end

      def run
          logger.debug("Creating consumer threads...")
          task_consumer_threads
          logger.debug("Consumer threads created.")

          until (terminate?) do
            scheduler_step
          end

          task_consumer_threads.each(&:exit)
          task_consumer_threads.each(&:join)
      end

      def create_task_consumer_thread
        Thread.new do 
          while (true) do
            task_consumer_step
          end
        end
      end

      def task_consumer_threads
        @task_consumer_threads ||= Array.new(task_consumer_thread_count) do | i | 
          create_task_consumer_thread
        end
      end 

      def task_consumer_step
        next_task = execution_queue.pop
        logger.debug("Popped task '#{next_task.name}' about to resume...")
        next_task.step
        logger.debug("Step returned. Putting task '#{next_task.name}' on done tasks queue.")
        done_tasks_queue.push(next_task)
      end

      def execution_queue
        @execution_queue ||= Queue.new
      end

      def done_tasks_queue
        @done_tasks_queue ||= Queue.new
      end

      def logger
        @logger ||= begin 
          logger = Logger.new(STDOUT)
          logger.level = Logger::ERROR
          logger
        end
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

