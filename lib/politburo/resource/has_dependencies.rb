module Politburo

  module Resource

    module HasDependencies

      def self.included(base)
        base.extend(ClassMethods)
      end

      def dependencies()
        @dependencies ||= []
      end

      def dependent_on?(dependency)
        dependencies.include?(dependency)
      end

      def add_dependency_on(target)
        raise "Can't add dependency on object that doesn't respond to #as_dependency" unless target.respond_to?(:as_dependency)

        dependency = target.as_dependency

        raise "Can't add dependency on a target that can't be resolved to a task" unless dependency.respond_to?(:to_task)

        dependencies << dependency
      end

      module ClassMethods
      end
    end

  end
end