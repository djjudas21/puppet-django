# Deploy a Django app from git
define django (
  $source,                     # Source of app in git
  $url,                        # URL that will be used to serve the app
  $path = "/var/www/${name}",  # Destination path on filesystem
  $ensure = 'present',
  $revision = undef,           # Revision of the app
  $ssl      = false,           # Enable SSL
  $identity = undef,           # SSH key for git repo
) {

  # Directory layout for a typical django app
  # /var/www/django-app    This level stored in the git repo and defined in $path
  # ├─ requirements.txt    Lists dependencies
  # ├─ virtualenv          Listed in .gitignore, generated by virtualenv
  # ├─ setup.py
  # └─ project-name        A collection of applications
  #    ├─ application1     One application per "feature"
  #    ├─ application2
  #    └─ project-name
  #       ├─ wsgi.py       Called by apache mod_wsgi
  #       └─ urls.py       Maps URLs onto applications

  # Initialise Apache and modules
  include apache
  include apache::mod::wsgi

  # Create the directory where the app will be installed
  file { $path:
    ensure => directory,
  }

  # Check out the app from version control
  vcsrepo { $name:
    ensure   => present,
    path     => $path,
    provider => 'git',
    source   => $source,
    revision => $revision,
    identity => $identity,
    require  => File[$path],
  }

  # Configure python
  class { 'python' :
    version    => 'system',
    pip        => true,
    dev        => true,
    virtualenv => true,
    gunicorn   => false,
  }

  # Create a virtualenv and install deps
  python::virtualenv { $name:
    ensure       => present,
    venv_dir     => "${path}/virtualenv",
    requirements => "${path}/requirements.txt",
    require      => Vcsrepo[$path],
  }

  # Install deps
  python::requirements { "${path}/requirements.txt":
    virtualenv => "${path}/virtualenv",
    require    => Vcsrepo[$path],
  }

  $port = $ssl ? {
    true    => 443,
    default => 80,
  }

  # Configure apache vhost
  apache::vhost { $url:
    docroot             => $path,
    port                => $port,
    wsgi_daemon_process => 'wsgi',
    wsgi_script_aliases => {
      '/' => "${path}/${name}/${name}/wsgi.py",
    },
    require             => Python::Virtualenv[$name],
  }

}
