module Politburo
  class DSL

    def initialize
    end

    def environment(opts, &block)
      environment = Environment.new(opts)

      environment.instance_eval(&block) if block_given?

      environment
    end

  end

  class Instance
    attr_accessor :name
    attr_accessor :facet

    def initialize(opts)
      raise ArgumentError.new("Missing :name argument for instance") unless opts.include?(:name)
      raise ArgumentError.new("Missing :facet argument for instance") unless opts.include?(:facet)
      @name = opts[:name]
      @facet = opts[:facet]
    end

    def deps
      facet.deps | (@deps ||= []) 
    end

    def dep(opts)
      (@deps ||= []) << Dep.new(opts)
    end

  end

  class Dep
    attr_accessor :name

    def initialize(opts)
      raise ArgumentError.new("Missing :name argument for dep") unless opts.include?(:name)
      @name = opts[:name]
    end
  end

  class Facet
    attr_accessor :deps
    attr_accessor :name
    attr_accessor :instances

    def initialize(opts)
      raise ArgumentError.new("Missing :name argument for facet") unless opts.include?(:name)
      @name = opts[:name]
    end

    def dep(opts)
      (@deps ||= []) << Dep.new(opts)
    end

    def instance(opts, &block)
      instance = Instance.new(opts.merge(:facet => self))
      (@instances ||= []) << instance
      
      instance.instance_eval(&block) if block_given?

      instance
    end
  end

  class Environment
    attr_accessor :facets
    attr_accessor :name

    def initialize(opts)
      raise ArgumentError.new("Missing :name argument for environment") unless opts.include?(:name)
      @name = opts[:name]
    end

    def facet(opts, &block)
      facet = Facet.new(opts)

      (@facets ||= []) << facet

      facet.instance_eval(&block) if block_given?

      facet
    end
  end

end
