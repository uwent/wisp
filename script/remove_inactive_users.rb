# remove users if they haven't logged in since 2015-1-1
User.where("last_sign_in_at is null").each do |user|
  puts "#{user.email} logged_in: #{user.last_sign_in_at}"
  user.destroy!
end

# clean up weather statios without a group
WeatherStation.all.each do |ws|
  if ws.group.nil?
    puts "WeatherStation: #{ws.id}"
    ws.destroy!
  end
end
