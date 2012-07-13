Politburo - The Babushka controlling DevOps orchestrator
========================================================

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
