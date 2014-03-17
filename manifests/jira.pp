class jira {
        exec{ 'createoptatla':
        command => 'sudo mkdir -p /opt/atlassian',
        path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ],
        logoutput =>true,
        onlyif => '[ ! -d /opt/atlassian ]',
        before  => Exec['createdataatla'],
        }

	exec{ 'createdataatla':
        command => 'sudo mkdir -p /data/atlassian',
        path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ],
        logoutput =>true,
        onlyif => '[ ! -d /data/atlassian ]',
        before  => Exec['createdatajira'],
        }

	exec{ 'createdatajira':
        command => 'sudo mkdir -p /data/atlassian/jira',
        path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ],
        logoutput =>true,
        onlyif => '[ ! -d /data/atlassian/jira ]',
        before  => Exec['adduser'],
        }

        exec {'adduser':
        command => 'sudo adduser jira',
        path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ],
        logoutput =>true,
        onlyif => '[ ! -e "/home/jira" ]',
        before => File['/home/jira/.profile'],
        }

	file {'/home/jira/.profile':
        source => 'puppet:///files/.profile',
        replace =>true,
	before => Group['atlaslog'],
        }

	group {'atlaslog':
        ensure => present,
        before => Exec['usermod'],
        }

	exec {'usermod':
        command => 'sudo usermod -a -G atlaslog jira',
        logoutput =>true,
        path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ],
	before => Exec['createuser'],
        }

	exec {'createuser':
        command => 'psql postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname=\'jira\'" | grep -q 1 || createuser -D -P jira',
	user=>'postgres',
        logoutput =>true,
        path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ],
	before => Exec['createdb'],
	require => Class['postgresql'],
        }
	
	exec {'createdb':
        command => 'createdb -O jira jira',
	user=>'postgres',
        logoutput =>true,
        path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ],
	onlyif => '[ ! psql -l | grep <exact_dbname> | wc -l ]',
	before => Exec['sshd_config'],
        }

	exec {'sshd_config':
        command => 'sudo echo "DenyUsers jira" >> /etc/ssh/sshd_config',
        logoutput =>true,
        path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ],
        before => Exec['restart'],
        }

	exec {'restart':
        command => 'sudo service ssh restart',
        logoutput =>true,
        path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ],
        before => Exec['wgetjira'],
        }

	exec {'wgetjira':
        command => 'sudo wget http://www.atlassian.com/software/jira/downloads/binary/atlassian-jira-6.1.7.tar.gz',
        cwd => '/opt/atlassian',
        logoutput =>true,
        path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ],
        onlyif => '[ ! -e "atlassian-jira-6.1.7-standalone" ]',
	before => Exec['tarjira'],
        }

	exec {'tarjira':
        command => 'sudo tar -zxvf atlassian-jira-6.1.7.tar.gz',
        cwd => '/opt/atlassian',
        logoutput =>true,
        path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ],
        onlyif => '[ ! -e "atlassian-jira-6.1.7-standalone" ]',
	before => Exec['rmjiragz'],
        }

	exec {'rmjiragz':
        command => 'sudo rm atlassian-jira-6.1.7.tar.gz',
        cwd => '/opt/atlassian',
        logoutput =>true,
        path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ],
        onlyif => '[ ! -e "atlassian-jira-6.1.7-standalone" ]',
	before => Exec['lnjira'],
        }

	exec {'lnjira':
        command => 'sudo ln -s atlassian-jira-6.1.7-standalone/ jira',
        cwd => '/opt/atlassian',
        logoutput =>true,
        path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ],
        onlyif => '[ ! -e "jira" ]',
	before => Exec['chownjira'],
        }

	exec {'chownjira':
        command => 'sudo chown -RH jira:jira /opt/atlassian/jira /data/atlassian/jira',
        cwd => '/opt/atlassian',
        logoutput =>true,
        path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ],
        onlyif => '[ ! -e "jira" ]',
	before => Exec['home-rolling'],
        }

#	exec {'export':
#        command => 'export JAVA_HOME=/opt/jvm/7',
#        user => 'jira',
#        logoutput =>true,
#        path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ],
#	before => Exec['home-rolling'],
#        }

#	exec {'config':
#        command => 'sh config.sh',
#	cwd => '/opt/atlassian/jira/bin',
#        user => 'jira',
#        logoutput =>true,
#        path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ],
#	before => Exec['home-rolling'],
#        }

	exec {'home-rolling':
        command => 'sudo sed -i -e "s/log4j.appender.filelog=com.atlassian.jira.logging.JiraHomeAppende/log4j.appender.filelog=com.atlassian.jira.logging.RollingFileAppender/g" jira/atlassian-jira/WEB-INF/classes/log4j.properties',
        logoutput =>true,
	cwd => '/opt/atlassian',
        path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ],
        before => Exec['home-rollingp2'],
        }
	
	exec {'home-rollingp2':
        command => 'sudo sed -i -e "s/log4j.appender.filelog.File=atlassianjira.log/log4j.appender.filelog.File=\/data\/logs\/atlassianjira.log/g" jira/atlassian-jira/WEB-INF/classes/log4j.properties',
        logoutput =>true,
	cwd => '/opt/atlassian',
        path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ],
        before => Exec['setenv'],
        }

	exec {'setenv':
        command => 'sudo echo "CATALINA_OUT=/data/logs/atlassianjiracatalina.out" >> jira/bin/setenv.sh',
	cwd => '/opt/atlassian',
        logoutput =>true,
        path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ],
	before  => Exec['createoptservice'],
	}

        exec{ 'createoptservice':
        command => 'sudo mkdir -p /data/logs',
        path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ],
        logoutput =>true,
        onlyif => '[ ! -d /data/logs ]',
       	}
}

