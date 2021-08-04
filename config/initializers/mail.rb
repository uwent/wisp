ActionMailer::Base.default from: 'cals-it-admin@cals.wisc.edu'

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

# Fix Chamber 2.x => 3.x deprecation warning
# url_options = Chamber.url_options.to_h.symbolize_keys
url_options = Chamber.dig!('url_options').to_h.symbolize_keys

Rails.application.routes.default_url_options = url_options
Rails.application.config.action_mailer.default_url_options = url_options
Rails.application.config.action_dispatch.default_url_options = url_options
