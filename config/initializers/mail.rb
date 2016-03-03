ActionMailer::Base.default from: 'jcpanuska@wisc.edu'

if ActionMailer::Base.delivery_method == :smtp
  ActionMailer::Base.smtp_settings = {
    address: 'smtp.sendgrid.net',
    port: '587',
    authentication: :plain,
    enable_starttls_auto: true,
    user_name: ENV['SENDGRID_USERNAME'],
    password: ENV['SENDGRID_PASSWORD'],
    domain: 'wisc.edu'
  }
end

url_options = {
  development: {
    host: localhost,
    port: 3000,
    protocol: http
  },
  test: {
    host: localhost,
    port: 9887,
    protocol: http
  },
  staging: {
    host: wisp-staging.herokuapp.com,
    port: nil,
    protocol: http
  }
}

Rails.application.routes.default_url_options = url_options
Rails.application.config.action_mailer.default_url_options = url_options
Rails.application.config.action_dispatch.default_url_options = url_options
