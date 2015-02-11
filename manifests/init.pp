# Deploy a Django app from git
class django (
  $source,  # Source of app in git
  $path,    # Destination path on filesystem
  $url,     # URL that will be used to serve the app
  $ensure = 'present',
  $revision = undef, # Revision of the app
  $ssl      = false, # Enable SSL
) {

  # Create the directory where the app will be installed
  file { $path:
    ensure => directory,
  }

  # Check out the app from version control
  vcsrepo { $path:
    ensure   => present,
    path     => $path,
    provider => 'git',
    source   => $source,
    revision => $revision,
    require  => File[$path],
  }

  # Create a virtualenv and install deps
  python::virtualenv { $path:
    ensure       => present,
    requirements => "${path}/requirements.txt",
    require      => Vcsrepo[$path],
  }

  # Initialise wsgi
  class { 'apache::mod::wsgi':
    wsgi_socket_prefix => "\${APACHE_RUN_DIR}WSGI",
    wsgi_python_home   => '/path/to/venv',
    wsgi_python_path   => '/path/to/venv/site-packages',
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
      '/' => "${path}/wsgi.py",
    },
    require             => Python::Virtualenv[$path],
  }

}
