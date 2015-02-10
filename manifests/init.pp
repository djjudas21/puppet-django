# Deploy a Django app from git
class django (
  $source,  # Source of app in git
  $path,    # Destination path on filesystem
  $url,     # URL that will be used to serve the app
  $ensure = 'present',
  $revision = undef, # Revision of the app
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
  }

}
