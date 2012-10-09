Politburo - The Babushka-wielding DevOps orchestrator
=====================================================================

Politburo is a tool to orchestrate launching, configuring, maintaining & 
updating entire multi-machine environments / clusters described in a 
simple DSL, using Babushka recipes.

> "Give me a lever long enough and a fulcrum on which to place it, 
> and I shall move the world" - Arhchimedes

The prologue:
-------------

* We love DevOps
* We like being able to describe our environments in code
* We believe that code should be the lever that allows single
  developers to orchestrate entire environments.
* We don't like Chef's complexity:
  * We don't like needed centralised servers
  * We don't like having to manage cookbooks
  * We don't like Chef's over-complicated recipe style 
  * We don't like the way that Chef recipes tend to bit-rot
* We love Babushka's approach to DevOps scripting:
  * Test-driven, self-describing idempotent, dependency based tasks.
  * Searchable, reusable & parameterised tasks with 
    '% successful run' metrics
* Babushka is missing a couple of things to allow it to wield it to
  manage multi-host environments/clusters:
  * A method of orchestrating multiple servers with inter-machine dependencies
  * A cron-able mechanism to run Babushka tasks
  * A dashboard view of your Babushka provisioned servers
* We like the ability to view and monitor our provisioned servers 
  from a web user interface

Aspirational Feature List:
--------------------------

* Secure, but not inconvenient
* Not dependent on a specialized server for orchestration
* Version control your environment(s) description
  * VCS, likely git, is the source of truth, 
  * A dashboard is just a view and/or tool to manipulate the 
    version-controlled truth
* Be agnostic of whether you are using pre-allocated hosts or 
  on-demand provisioned ones (either Cloud or VMs.)
* Dependencies between hosts & roles 
  * Classic situation: You may need your master node fully 
    configured before your slave can start.
  * Classic situation: NFS master node must be available before 
    you start your NFS clients
* Blueprint environments + modifications:
  * You may want multiple staging environment, that are 99% simliar.
    You do not want to have to duplicate & maintain multiple descriptors.

Politburo DSL Basics:
---------------------

* The DSL describes a hierarchy of resources
  * e.g. An example production environment is _composed of_ one load 
    balancer, one database master, one database slaves and three web-nodes
  * The production environment is a resource, and so are the load balancer, 
    db master and each of the web nodes. 
  * The environment resource contains the other resources.
* The DSL is designed to be run in parallel. It is translated to
  a hierarchy of dependencies, most of which are remote tasks
* A hierachical relationship is simply syntactic sugar to imply dependency.
  * e.g. To mark the production environment as ready, all the composite 
    parts of the production environment such as the load balancer and 
    the database master must be ready. Therefore the production 
    environment is _dependent_ on all its sub-resources
* Naturally, you can still have dependency across the tree, other than on 
  your sub-resources
  * e.g. The webnodes for a standard LAMP stack are dependent on the master 
    db node being ready, even though they don't hierarchically 'own' the dbnode. 
* Resources lifecycle
  * All resources share a minimum of these life-cycle states: "Defined", "In Progress", "Ready"

