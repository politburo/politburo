Politburo - The Babushka controlling DevOps dashboard
=====================================================

The prologue:
-------------

* We love DevOps
* We like being able to describe our environments in code
* We like the ability to view and monitor our provisioned servers from a web user interface
* We don't like Chef's complexity:
  * We don't like having to manage cookbooks
  * We don't like Chef's over-complicated DSL 
  * We don't like the way that Chef recipes tend to bit-rot
* We love Babushka's approach to DevOps scripting:
  * Test-driven, self-describing idempotent sysadmin tasks.
  * Searchable, reusable tasks with '% successful run' metrics
* Babushka was missing a couple of things to allow it to replace Chef:
  * A dashboard view of your Babushka provisioned servers
  * A cron-able mechanism to run Babushka tasks
  * A method of describing multiple Babushka configured servers in one point

