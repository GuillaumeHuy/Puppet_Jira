import 'java.pp'
import 'postgresql.pp'
import 'jira.pp'

class git{
        package{ 'git':
        ensure => installed,
        }
}


node default {
	include java
	include postgresql
	include git
	include jira
}
