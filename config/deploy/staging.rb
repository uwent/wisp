server 'dev.wisp.cals.wisc.edu',
  user: 'deploy',
  roles: %w{app db web},
  ssh_options: {
    port: 216,
    forward_agent: true
  }

set :rails_env, 'production'
