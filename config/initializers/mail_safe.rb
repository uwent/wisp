if defined?(MailSafe::Config)
  MailSafe::Config.internal_address_definition = lambda do |address|
    valid_patterns = [
      /\Amark(\+.*)?@mceahern\.com\z/i,
      /\Amark\.mceahern(\+.*)?@gmail\.com\z/i,
      /\Ajcpanuska@wisc\.edu\z/i
    ]

    valid_patterns.any? do |pattern|
      address =~ pattern
    end
  end

  MailSafe::Config.replacement_address = lambda do |address|
    return `git config user.email`.chomp if Rails.env.development? || Rails.env.test?

    "mark@mceahern.com"
  end
end
