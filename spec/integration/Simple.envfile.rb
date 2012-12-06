environment(name: 'simple', description: "Simple integration test environment", flavor: :simple) do
  node(name: "node", host: 'localhost') {}
  node(name: "another node", host: 'localhost') do
    depends_on node(name: "node").state(:configured)
  end
  node(name: "yet another node", host: 'localhost') do
    state('configured') do 
      depends_on node(name: "node")
    end
  end
end
