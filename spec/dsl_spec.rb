require 'politburo'

describe "DSL" do
  before :each do
    @dsl = Politburo::DSL.new
  end

  it "should instantiate" do
    @dsl.should be_true
  end

  describe "#{}environment" do
    it "should be able to describe an environment" do
      environment = @dsl.instance_eval do
        environment(:name => 'development') do
        end
      end

      environment.name.should eql('development')
    end

    it "should raise an error if name isn't provided" do
      lambda { @dsl.instance_eval { environment } }.should raise_error
    end
  end

  it "should be able to describe multiple facets" do
    environment = @dsl.instance_eval do
      environment(:name => 'development') do
        facet(:name => 'load balancer')
        facet(:name => 'webserver')
        facet(:name => 'database')
      end
    end

    environment.facets.size.should eql(3)
    environment.facets.first.name.should eql('load balancer')
    environment.facets.last.name.should eql('database')
  end

  describe "facets" do
    it "should nominate the babushka deps to run" do

      environment = @dsl.instance_eval do
        environment(:name => 'development') do
          facet(:name => 'load balancer') do
            dep(:name => 'robertpostill:ohai')
            dep(:name => 'redbeard:enable universal source')
          end
        end
      end
      
      facets = environment.facets
      load_balancer = facets.first
      load_balancer.name.should eql('load balancer')
      
      deps = load_balancer.deps
      deps.first.name.should eql('robertpostill:ohai')
      deps.last.name.should eql('redbeard:enable universal source')
    end

    it "should be able to describe multiple instances" do
      environment = @dsl.instance_eval do
        environment(:name => 'development') do
          facet(:name => 'load balancer') do
            dep(:name => 'robertpostill:ohai')
            instance(:name => 'load-balancer-1', :host => '192.168.0.2') do
              dep(:name => 'redbeard:enable universal source')
            end
          end
        end
      end
      
      instance = environment.facets.first.instances.first
      instance.name.should eql('load-balancer-1')

      deps = instance.deps
      deps.first.name.should eql('robertpostill:ohai')
      deps.last.name.should eql('redbeard:enable universal source')
      
    end  
      
  end

end
