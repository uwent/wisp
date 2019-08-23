server '52.36.85.186',
  user: 'deploy',
  roles: %w{app db web},
  ssh_options: {
    port: 216,
    forward_agent: true
  }
