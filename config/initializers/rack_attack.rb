# config/initializers/rack_attack.rb

class Rack::Attack
  # Throttle requests per second per IP
  throttle('req/ip', limit: 25, period: 1.second) do |req|
    req.ip
  end

  # Stricter throttling for API endpoints
  # throttle('api/ip', limit: 100, period: 1.hour) do |req|
  #   req.ip if req.path.start_with?('/api/')
  # end

  # Throttle POST/PUT/PATCH/DELETE requests more strictly
  throttle('writes/ip', limit: 5, period: 1.second) do |req|
    req.ip if %w[POST PUT PATCH DELETE].include?(req.request_method)
  end

  # Block requests from bad IPs (example)
  # blocklist('block bad IPs') do |req|
  #   # Replace with real IPs to block
  #   ['1.2.3.4', '5.6.7.8'].include?(req.ip)
  # end

  # Block suspicious requests for '/etc/password' or wordpress specific paths.
  # After 3 blocked requests in 10 minutes, block all requests from that IP for 5 minutes.
  blocklist('fail2ban pentesters') do |req|
    # `filter` returns truthy value if request fails, or if it's from a previously banned IP
    # so the request is blocked
    Fail2Ban.filter("pentesters-#{req.ip}", maxretry: 3, findtime: 10.minutes, bantime: 5.minutes) do
      # The count for the IP is incremented if the return value is truthy
      CGI.unescape(req.query_string) =~ %r{/etc/passwd} ||
      req.path.include?('/etc/passwd') ||
      req.path.include?('wp-admin') ||
      req.path.include?('wp-login') ||
      req.path.include?('phpMyAdmin') ||
      req.path.include?('.env') ||
      req.path.include?('config.php') ||
      req.path =~ %r{/\.git/} ||
      req.path.include?('wp-config.php')
    end
  end

  # Lockout IP addresses that are hammering your login page.
  # After 20 requests in 1 minute, block all requests from that IP for 1 hour.
  blocklist('allow2ban login scrapers') do |req|
    # `filter` returns false value if request is to your login page (but still
    # increments the count) so request below the limit are not blocked until
    # they hit the limit.  At that point, filter will return true and block.
    Allow2Ban.filter(req.ip, maxretry: 20, findtime: 1.minute, bantime: 1.hour) do
      # The count for the IP is incremented if the return value is truthy.
      (req.path == '/login' || req.path == '/wisp/sign_in') && req.post?
    end
  end

  # Protect authentication endpoints
  throttle('auth/ip', limit: 5, period: 20.seconds) do |req|
    req.ip if req.path =~ %r{/wisp/(sign_in|sign_up|password)} && req.post?
  end

  # Throttle password reset attempts
  throttle('password_reset/ip', limit: 3, period: 1.hour) do |req|
    req.ip if req.path.include?('password') && req.post?
  end

  # Throttle registration attempts
  throttle('registration/ip', limit: 5, period: 1.hour) do |req|
    req.ip if req.path =~ %r{/wisp/sign_up} && req.post?
  end

  # Protect against form spam on data endpoints
  throttle('post_data/ip', limit: 30, period: 1.minute) do |req|
    req.ip if req.path.include?('post_data') && req.post?
  end

  # Block requests with suspicious user agents
  blocklist('bad user agents') do |req|
    ua = req.user_agent.to_s.downcase
    ua.include?('sqlmap') ||
    ua.include?('nmap') ||
    ua.include?('nikto') ||
    ua.include?('masscan') ||
    ua.include?('zap') ||
    ua.empty? ||
    ua == '-'
  end

  # Block requests trying to access sensitive files
  blocklist('sensitive files') do |req|
    req.path =~ %r{\.(log|sql|backup|bak|old|tmp)$} ||
    req.path.include?('database.yml') ||
    req.path.include?('secrets.yml') ||
    req.path.include?('.env')
  end

  # Allow all local traffic
  safelist('allow from localhost') do |req|
    ['127.0.0.1', '::1'].include?(req.ip)
  end

  # Allow requests from load balancers or CDNs (adjust IPs as needed)
  # safelist('allow from load balancer') do |req|
  #   ['10.0.0.0/8', '172.16.0.0/12', '192.168.0.0/16'].any? do |range|
  #     IPAddr.new(range).include?(IPAddr.new(req.ip))
  #   end
  # end

  # Custom response for throttled requests
  self.throttled_responder = lambda do |env|
    [ 429,  # status
      { 'Content-Type' => 'application/json' }, 
      [{ error: 'Rate limit exceeded' }.to_json]
    ]
  end

  # Custom response for blocked requests
  self.blocklisted_responder = lambda do |env|
    [ 403,  # status
      { 'Content-Type' => 'application/json' },
      [{ error: 'Forbidden' }.to_json]
    ]
  end
end
