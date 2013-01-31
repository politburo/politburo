environment(name: "Complex integration test environment", provider: :aws) do

  # This defines the database master + slaves
  %w(us-west-1 us-west-2 us-east-1).each do | region |
    group(name: "Database", region: region) do
      database_master(name: "Database Master", flavor: "c1.xlarge", database_provider: "postgres") { }
      group(name: "Database Slaves") {
        1..3.each { | i | 
          database_slave(name: "Database Slave ##{i}", flavor: "m1.large", database_provider: "postgres") do
            state(:starting).depends_on database_master(name: "Database Master").state(:ready)
          end
        }
      }
    end
  end

  # This defines the load-balancer + webserver nodes
  group(name: "Webnodes") do
    state(:configuring).depends_on facet(name: "Database").state(:running)
    webnode(name: "Load Balancer", flavor: "c1.xlarge") do
      # At the very least, the IP addresses for the slaves would be required to configure the load balancer
      state(:ready_to_configure) { depends_on facet(name: "Webnode Instances").state(:running) }
    end
    facet(name: "Webnode Instances", cardinality: 2) do
      webnode(name: "Webnode", flavor: "m1.large") do
      end
    end 
  end

end
