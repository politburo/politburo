environment(name: 'simple', description: "Simple integration test environment", environment_flavour: :simple) do
  node(name: "node") {}
  node(name: "another node") do
    depends_on node(name: "node").state(:configured)
  end
  node(name: "yet another node") do
    state('configured').depends_on node(name: "node")
  end
end
