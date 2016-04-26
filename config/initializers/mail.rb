ActionMailer::Base.default from: 'jcpanuska@wisc.edu'

if ActionMailer::Base.delivery_method == :smtp
  if Rails.env.staging?
    ActionMailer::Base.smtp_settings = {
      address: 'smtp.sendgrid.net',
      port: '587',
      authentication: :plain,
      enable_starttls_auto: true,
      user_name: ENV['SENDGRID_USERNAME'],
      password: ENV['SENDGRID_PASSWORD'],
      domain: 'wisc.edu'
    }
  else
    ActionMailer::Base.smtp_settings = {
      address: 'localhost',
      openssl_verify_mode: 'none',
      domain: 'wisc.edu'
    }
  end
end

url_options = Chamber.url_options.to_h.symbolize_keys

Rails.application.routes.default_url_options = url_options
Rails.application.config.action_mailer.default_url_options = url_options
Rails.application.config.action_dispatch.default_url_options = url_options
