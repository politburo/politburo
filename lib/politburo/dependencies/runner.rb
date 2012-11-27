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
        return true unless failed_tasks.empty?

        next_task = pick_next_task

        return true if !next_task.nil? and next_task.failed?
        return true if @start_with.all?(&:done?)

        false
      end

      def failed_tasks
        @failed_tasks ||= []
      end

      def clear_progress_flag_on_done_tasks
        until (done_tasks_queue.empty?)
          task = done_tasks_queue.pop
          task.in_progress = false
          failed_tasks << task if (task.failed?)
        end
      end

      def scheduler_step
        clear_progress_flag_on_done_tasks
        return unless (failed_tasks.empty?)

        next_task = pick_next_task
        if next_task and !next_task.failed?
          logger.debug("Adding task #{next_task.name.yellow} [#{next_task.object_id}] to the execution queue.")
          raise "Assertion failed. Task #{next_task.name.yellow} [#{next_task.object_id}] provided, but is not available for queueing! (State: #{next_task.state})" unless next_task.available_for_queueing?
          next_task.step if next_task.unexecuted?
          next_task.in_progress = true
          execution_queue.push(next_task)
        else
          logger.debug("Waiting for tasks to become available...")
          Kernel.sleep(0.01)
        end
      end

      def run
          logger.debug("Will start runner with following initial tasks: #{start_with.map(&:name).join(', ')}")
          logger.debug("Creating consumer threads...")
          task_consumer_threads
          logger.debug("Consumer threads created.")

          until (terminate?) do
            scheduler_step
          end

          failed_tasks.each do | next_task |
            logger.error("Task '#{next_task.name.yellow}' failed with error: '#{next_task.cause_of_failure.to_s.red}'. Trace:\n\t#{next_task.cause_of_failure.backtrace.nil? ? 'N/A' : next_task.cause_of_failure.backtrace.join("\n\t")}")
          end

          task_consumer_threads.each(&:exit)
          task_consumer_threads.each(&:join)

          logger.debug "Finished run."

          return failed_tasks.empty?
      end

      def create_task_consumer_thread
        Thread.new do 
          begin
            while (true) do
              task_consumer_step
            end
          ensure
            logger.debug "Task consumer thread finished."
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
        logger.debug("Popped task '#{next_task.name.yellow} [#{next_task.object_id}]' about to resume...")
        next_task.step
        logger.debug("Step returned. Putting task '#{next_task.name.yellow}' on done tasks queue.")
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
          logger.level = Logger::INFO
          logger
        end
      end

      private 

      class TaskVisitor
        def logger
          @logger ||= begin 
            logger = Logger.new(STDOUT)
            logger.level = Logger::INFO
            logger
          end
        end

        def visit(path, *tasks)
          tasks.each do | task |
            logger.debug("Visiting #{task.name}...")
            visited.add(task)
            task.paths << path
            raise "Cyclical dependency detected. Task '#{task.name}' is prerequisite of itself. Cycle: #{(path + [ task ]).map(&:name).join(' -> ')}" if path.include?(task)
            if task.all_prerequisites_satisfied? and task.available_for_queueing?
              logger.debug("Task #{task.name} is ready for queueing.")              
              have_no_unsatisfied_dependencies << task 
            else
              logger.debug("Task prerequisites: '#{task.prerequisites.map(&:name).join(", ")}' ")              
              prereqs = task.unsatisfied_idle_prerequisites
              logger.debug("Will visit task prerequisites: '#{prereqs.map(&:name).join(", ")}' ")              
              self.visit(path + [ task ], *prereqs)
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

