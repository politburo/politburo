Politburo - The Ruby Dev's DevOps Weapon of Mass Creation
================================================================

Politburo is a Ruby-based DSL that lets you describe entire environments in 
declarative code, and launch them with a single command. 

Launch in the cloud, or locally. It is still Ruby, with all that implies.

Remote tasks are written in Babushka.

Inspiration
-------------

> "Give me a lever long enough and a fulcrum on which to place it, 
> and I shall move the world" - Arhchimedes

Or:

> "First requisite of get shit done is be
>          able for deal with lot of shit." - @DEVOPS_BORAT (http://goo.gl/FCxTz)

Quick example:
-------------

This is an example that shows the basics of the Politburo DSL.

```ruby
environment(name: "tiny") do

  database(name: "db") {}

  webnode(name: "front facing") do
    depends_on database("db")
    application(repo: "git://...")
  end

end
```

You launch this environment with:
```politburo tiny#ready```

You terminate it with:
```politburo tiny#terminated```

To terminate just the front-facing webnode:
```politburo "tiny:front facing#terminated"```

Why?
-------------

### Environmments are code ###

* We like being able to describe our environments in code

* Source of truth should be in our code.

* We believe that code should be the lever that allows single developers to orchestrate entire environments.

* The difference between a test environment and a production one is
  in the number of servers while the topology is the same -- 
  therefore there should only be one copy of the environment's description with
  parameters controlling the difference.

* In the cloud, environments code you

### Test your environments ###

* Your build pipeline should be testing your deployment, which also includes your provisioning and how your different machines interact.

### Dev ≈ Test ≈ Prod ###

* Difference between dev, test, prod should be cardinality, not topology.
* Dev might be local VMs, prod might be AWS. That shouldn't stop you.

Politburo DSL Basics:
---------------------

Note this example:
```ruby
environment(name: "tiny", provider: :aws) do

  group(name: "databases") do
    database(name: "master") {}
    database(name: "slave") do
      depends_on database("master")
    end
  end

  webnode(name: "front facing") do
    depends_on group("databases")
    application(repo: "git://...")
  end

end
```

* The DSL describes a hierarchy of resources
  * The hierarchy is syntactic sugar for a 'depends on' relationship.
  * e.g. The 'tiny' environment above is _composed of_ a database group and a front-facing webnode. This means the environment is considered _ready_ when both the database group and the front-facing webnode are _ready_.
* ```resource(attributes: ...) {}``` = Defining a resource
* ```resource(attr: ...)``` = Referring to a resource
* The DSL is designed to be run in parallel. It is translated to
  a hierarchy of dependencies, most of which are remote tasks
* Naturally, you can still have dependency across siblings
  * ```{ depends_on other_resource(attrs:) }```
* Resources lifecycle - all resources share a minimum of these life-cycle states: 
  * defined -> created -> starting -> started -> configuring -> configured -> ready. 
  * stopping -> stopped -> terminated

### It is still Ruby ###

```ruby
environment(name: "biggie", provider: :aws) do
  regions.each do | region |
    group(name: "#{region}", region: region) do
      group(name: "databases") { ... }
      group(name: "webnodes") do
        load_balancer(name: "webnodes")
        (1..10).each do | i | 
          webnode(name: "webnode #{i}") { ... }
        end
        depends_on group(name: 'databases')
      end
    end
  end
end
```

You can launch just the us-west-1 region:

```politburo biggie:us-west-1#ready```

### You can define your own roles and types ###

```ruby
role(:elasticsearch_server) {
  state(:configured) {
    babushka_task(dep: 'politburo:elasticsearch-installed', args: { version: "0.20.5", port: 9200, cluster_name: environment({}).name }) { }
  } 
}

type(:elasticsearch_node, based_on: :node) do
  implies do
    role(:elasticsearch_server)
  end
end

type(:web_app_node, based_on: :node) do
  attr_accessor :es_node
  requires :es_node

  implies do
    role(:git_client)
    # .. more roles here

    depends_on es_node
  end

end

environment(name: 'example', description: "example environment",
  provider: :aws, 
  provider_config: { aws_access_key_id: ENV['AWS_ACCESS_KEY_ID'], aws_secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'] } ) do

  group(name: "Sydney", region: 'ap-southeast-2') do
    elasticsearch_node(name: "ElasticSearch Node", user: 'ubuntu') { }
    web_app_node(name: "Rails App Node", 
      user: 'ubuntu', 
      es_node: elasticsearch_node(name: "ElasticSearch Node") ) {}
  end

end
```

Why not (insert DevOps tool here)
-------------

Why not Chef? Puppet? Ansible? Capistrano? CloudFormation? Vagrant? Pallet? 

So many tools try to scratch the itch, but we found that we still had an itch.

### How come? ###

* We don't want centralised configuration servers
  * Why not launch a 100-machine cluster from our laptop?
  * Source of truth should be version controlled.

* We don't like recipes that are brittle or suffer from bit-rot
  * We want test-driven, self-describing idempotent, dependency based tasks.
  * We don't like having to manage cookbooks
  * Cookbook version hell is not acceptable.

### Inter-machine dependencies ###

* Classic situation: You may need your master node fully configured before your slave can start. 

Examples:

* NFS master node must be available before you start your NFS clients

* Hadoop HDFS namenode should be up before job servers can be started

### Single threading is passe ###

* Why not resolve dependencies in parallel? Politburo, as the organizing comittee, wields many Babushkas in parallel.

### Vendor lock-in sucks ###

* That goes for Cloud providers.
  * Politburo is written with Fog, should be easy to add support for Cloud providers
  * Should be able to describe an environment that crosses Cloud provider boundaries
* We want predictability, at the end of the tool's run we want to know
  it is in a known state.

What's with the name?
-------------
Политбюро IPA: [pəlʲɪtbʲʉˈro]
"Political Bureau of the Central Committee of the Communist Party of the Soviet Union"

As the DSL orchestrates an army of Babushka deps, we thought it was appropriate.

TODO
-------------

(a.k.a Five-Year Plans for the National Economy of the Soviet Union)

* Support for providers other than AWS and local servers- Rackspace, etc.

* More recipes for Rails and other stacks

* Plug-ins to automatically construct Newrelic or other monitoring for environments

Contributors:
-------------
* Tal Rotbart (@rotbart)

* Robert Postill (@robertpostill)

* Thanks to Cameron Hine and Navin Peiris (@navinpeiris) for their contributions

License:
--------------

Licensed under the simplified BSD (2 clause) license. See LICENSE file.

