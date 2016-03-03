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
