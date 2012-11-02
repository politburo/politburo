environment(name: "Complex integration test environment", flavour: :amazon_web_services) do

  # This defines the database master + slaves
  facet(name: "Database", cardinality: 1) do
    database_master(name: "Database Master", flavour: "c1.xlarge", database_flavour: "postgres") do
    end
    facet(name: "Database Slaves", cardinality: 2) do
      database_slave(name: "Database Slave", flavour: "m1.large", database_flavour: "postgres") do
        depends_on database_master(name: "Database Master").state(:ready)
      end
    end
  end

  # This defines the load-balancer + webserver nodes
  facet(name: "Webnodes") do
    depends_on facet(name: "Database")
    webnode(name: "Load Balancer", flavour: "c1.xlarge") do
      # At the very least, the IP addresses for the slaves would be required to configure the load balancer
      state(:ready_to_configure).depends_on facet(name: "Webnode Instances").state(:running) 
    end
    facet(name: "Webnode Instances", cardinality: 2) do
      webnode(name: "Webnode", flavour: "m1.large") do
      end
    end 
  end

end
