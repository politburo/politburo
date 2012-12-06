environment(name: "Complex integration test environment", provider: :amazon_web_services) do

  import 'redbeard:webnode'

  # This defines the database master + slaves
  facet(name: "Database", cardinality: 3) do
    database_master(name: "Database Master", provider: "c1.xlarge", database_provider: "postgres") do
    end
    facet(name: "Database Slaves", cardinality: 2) do
      database_slave(name: "Database Slave", provider: "m1.large", database_provider: "postgres") do
        state(:starting).depends_on database_master(name: "Database Master").state(:starting)
      end
    end
  end

  # This defines the load-balancer + webserver nodes
  facet(name: "Webnodes") do
    state(:configuring).depends_on facet(name: "Database").state(:running)
    webnode(name: "Load Balancer", provider: "c1.xlarge") do
      # At the very least, the IP addresses for the slaves would be required to configure the load balancer
      state(:ready_to_configure) { depends_on facet(name: "Webnode Instances").state(:running) }
    end
    facet(name: "Webnode Instances", cardinality: 2) do
      webnode(name: "Webnode", provider: "m1.large") do
      end
    end 
  end

end
