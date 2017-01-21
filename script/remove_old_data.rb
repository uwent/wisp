# Remove the older than 2015 pivots
Pivot.where("cropping_year < 2015").each do |p| 
  puts "Destroy pivot: #{p.id}: #{p.cropping_year}"
  p.destroy!
end


# remove the farms without any pivots
Farm.all.each do |farm| 
  if farm.pivots.length == 0
    puts "Dstroy farm: #{farm.id}" 
    farm.destroy!
  end
end

# remove the groups without any farms
Group.all.each do |group| 
  if group.farms.length == 0
    puts "Group: #{group.id}" 
    group.destroy!
  end
end

# remove the users without a group
User.all.each do |user| 
  if user.groups.length == 0
    puts "User: #{user.id}, #{user.name}" 
    user.destroy!
  end
end

# clean up weather statios without a group
WeatherStation.all.each do |ws| 
  if ws.group.nil?
    puts "WeatherStation: #{ws.id}"
    ws.destroy!
  end
end

# clean up the duplicated pivots for a farm:
Farm.all.each do |farm| 
  created_ats = farm.pivots.map(&:created_at).uniq
  created_ats.each do |ca| 
    pivots = farm.pivots.where(created_at: ca).order(:id)
    if pivots.length > 1
      puts "Farm: #{farm.id} -- #{farm.name}"
      puts "    Leaving pivot: #{pivots[0].id}"
      pivots[1..-1].each do |p| 
        p.destroy!
        puts "    Removing pivot: #{p.id}"
      end
    end
  end
end
