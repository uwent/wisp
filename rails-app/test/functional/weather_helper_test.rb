require 'test_helper'

class WeatherHelperTest < ActionView::TestCase
  def setup
    @yesterday = 1.days.ago
    @y_julian = @yesterday.strftime("%Y%j")
    @today = Date.today
    @today_ymd = date_to_url_str(@today)
    @title = 'fnord'
    @last_week = 1.week.ago
  end
  
  def test_hyd_link_today
    thl = todays_hyd_link
    assert(thl =~ /#{@y_julian}/)
    assert(thl =~ /http:\/\//)
    assert(thl =~ /^<a href=/)
  end
  
  def test_webcam_link_default
    wal = webcam_archive_link @title
    assert(wal)
    assert_has_date(wal,@today)
    assert_without_movie(wal)
    assert_has_title(wal,@title)
  end
  
  def test_webcam_link_title
    wal = webcam_archive_link(@title)
    assert(wal)
    assert_has_date(wal,@today)
    assert_without_movie(wal)
    assert_has_title(wal,@title)
  end
  
  def test_webcam_link_days_ago
    wal = webcam_archive_link(@title,:days_ago => 7)
    assert(wal)
    assert_has_date(wal,@last_week)
    assert_without_movie(wal)
    assert_has_title(wal,@title)
  end

  def test_webcam_link_days_ago_no_title
    wal = webcam_archive_link(nil,:days_ago => 7)
    assert(wal)
    assert_has_date(wal,@last_week)
    assert_without_movie(wal)
    assert_has_title(wal,'')
  end

  def test_webcam_link_movie
    wal = webcam_archive_link(@title,:movie => true)
    assert(wal)
    assert_has_date(wal,@today)
    assert_has_movie(wal)
    assert_has_title(wal,@title)
  end
  
  def test_webcam_link_all_options
    wal = webcam_archive_link(@title,:days_ago => 7, :movie => true)
    assert(wal)
    assert_has_date(wal,@last_week)
    assert_has_movie(wal)
    assert_has_title(wal,@title)
  end
  
  def test_has_opt
    wal = webcam_archive_link(@title,{:days_ago => 7},{:class => 'bar-lit'})
    assert(wal)
    assert_has_date(wal,@last_week)
    assert_has_opt(wal," class='bar-lit'")
  end
  private
  
  def assert_has_date(url,date)
    assert(url.include?(date_to_url_str(date)) ,"Wrong date: URL #{url}oes not include path '#{date_to_url_str(date)}'")
  end
  
  def assert_has_movie(url)
    assert(url =~ /[\d\d]\/movie.html'>/,"No Movie: Path part of URL #{url}should end with /movie.html")
  end
  
  def assert_without_movie(url)
    assert(url =~ /[\d\d]\/'>/,"W/O Movie: Path part of URL #{url} should end with nn/'>")
  end
  
  def assert_has_title(url,title=@title)
    assert(url =~ /[\d\d]\/.*'>#{title}<\/a>$/,
      "Wrong title: '#{url}' should end with 'nn/'>#{title}</a>'" +
        " but ends with '#{url[-32..-1]}'")
  end

  def assert_has_opt(url,opt_str)
    assert(url =~ /'#{opt_str}>/,"URL #{url} should have included #{opt_str}")
  end
  
  def date_to_url_str(date)
    date.strftime("%Y/%m/%d")
  end

end
