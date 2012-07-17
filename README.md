Politburo - The Babushka wielding DevOps orchestrator
========================================================

Politburo is a tool to orchestrate launching entire environments described in a simple DSL, using Babushka recipes.

The prologue:
-------------

* We love DevOps
* We like being able to describe our environments in code
* We don't like Chef's complexity:
  * We don't like having to manage cookbooks
  * We don't like Chef's over-complicated DSL 
  * We don't like the way that Chef recipes tend to bit-rot
* We love Babushka's approach to DevOps scripting:
  * Test-driven, self-describing idempotent sysadmin dependency based tasks.
  * Searchable, reusable tasks with '% successful run' metrics
* Babushka was missing a couple of things to allow it to replace Chef:
  * A method of orchestrating multiple servers
  * A cron-able mechanism to run Babushka tasks
  * A dashboard view of your Babushka provisioned servers
* We like the ability to view and monitor our provisioned servers from a web user interface

Aspirational Feature List:
--------------------------

* Secure, but not inconvenient
* Not dependent on a specialized server for orchestration
* Version control your environment(s) description
  * VCS, likely git, is the source of truth, 
  * A dashboard is just a view and/or tool to manipulate the version-controlled truth
* Be agnostic of whether you are using pre-allocated hosts or on-demand provisioned ones (either Cloud or VMs.)
* Dependencies between hosts & roles 
  * Classic situation: You may need your master node fully configured before your slave can start.
  * Classic situation: NFS master node must be available before you start your NFS clients
* Blueprint environments + modifications:
  * You may want multiple staging environment, that are 99% simliar. You do not want to have to duplicate & maintain multiple descriptors.

Politburo DSL Basics:
---------------------

* The DSL is designed to be executed by Babushka
* The DSL describes a hierarchy of resources
  * e.g. An example production environment is _composed of_ one load balancer, one database master, one database slaves and three web-nodes
  * The production environment is a resource, and so are the load balancer, db master and each of the web nodes. 
  * The environment resource contains the other resources.
* A hierachical relationship is simply syntactic sugar to imply dependency.
  * e.g. To mark the production environment as ready, all the composite parts of the production environment such as the load balancer and the database master must be ready. Therefore the production environment is _dependent_ on all its sub-resources
* Naturally, you can still have dependency across the tree, other than on your sub-resources
  * e.g. The webnodes for a standard LAMP stack are dependent on the master db node being ready, even though they don't hierarchically 'own' the dbnode. 
* Resources lifecycle
  * All resources share a minimum of these life-cycle states: "Defined", "In Progress", "Ready"