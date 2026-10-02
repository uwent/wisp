namespace :precip do
  # From June 2026 until the Phase 0 hotfix, Field#get_precip skipped the AgWeather fetch for groups
  # set to "Auto" (the default) and fetched it for groups set to "Manual". This refills rainfall
  # for current-season fields in Auto groups. get_precip only fills days whose rain is nil or zero,
  # so user-entered values (including entered zeros, stored as 0.00001) are kept.
  desc "Backfill AgWeather rainfall for current-season fields in Auto groups (DRY_RUN=1 to preview)"
  task backfill: :environment do
    dry_run = ENV["DRY_RUN"].present?
    year = Date.current.year
    fields = Field.joins(pivot: {farm: :group})
      .where(groups: {precip_use_agwx: true}, pivots: {cropping_year: year})

    puts "#{dry_run ? "[DRY RUN] " : ""}#{fields.count} current-season fields in Auto groups"

    filled = failed = 0
    fields.find_each do |field|
      missing = field.field_daily_weather.where(date: ..Date.current).where(rain: [nil, 0.0]).count
      if dry_run
        puts "  field #{field.id}: #{missing} past days with no rainfall"
        next
      end
      field.get_precip
      field.do_balances
      filled += 1
      puts "  field #{field.id}: refreshed (#{missing} past days had no rainfall)"
    rescue => e
      failed += 1
      puts "  field #{field.id}: FAILED #{e.class}: #{e.message}"
    end
    puts "Refreshed #{filled} fields, #{failed} failures" unless dry_run

    # Manual groups received AgWeather rainfall they didn't ask for while the bug was live. Those
    # values can't be told apart from user entries automatically, so just report who is affected.
    manual = Group.where(precip_use_agwx: false)
    puts "\n#{manual.count} groups are set to Manual and may have unwanted AgWeather rainfall since June 2026:"
    manual.includes(:users).find_each do |group|
      puts "  group #{group.id}: #{group.users.map(&:email).join(", ")}"
    end
  end
end
