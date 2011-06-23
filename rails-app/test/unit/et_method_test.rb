require 'test_helper'

class EtMethodTest < ActiveSupport::TestCase
  DELTA = 0.00000001 # delta for floating-point equality tests
  def setup
    @adjET = nil
    @refET = 0.2
    @pctCover = 0.3
    @pcm = et_methods(:pct_cover)
    @weather = fields(:one).field_daily_weather.sort {|w1,w2| w1.date <=> w2.date}
    # these ET values surround the corner cases in the percent cover adjusted ET algorithm
    @ref_ets = [0.0, 0.15, 0.159, 0.16, 0.161, 0.318, 0.319, 0.320]
  end
  
  test "can call adjET for pct cover case" do
    
    assert(@pcm,"Should be a percent cover method in the database")
    assert_nothing_raised(Exception) { @adjET = @pcm.adjETPctCover(@refET,@pctCover)}
    assert(@adjET, "Should have calculated an adjusted ET")
  end
  
  test "can polymorphically call adjET" do
    assert_nothing_raised(Exception) { @pcm.adj_et({:ref_et => @refET, :pct_cover => @pctCover}) }
  end
  
  test "adjusted ET for zero ref ET and zero pct cover" do
    assert_equal(0.0, @pcm.adj_et({:ref_et => 0.0, :pct_cover => 0.0}))
  end
  
  test "adjusted ET with zero percent cover" do
    expected_adj_ets = [0.0, 0.0, 0.0, 0.01, 0.01, 0.01, 0.01, 0.02]
    ii = 0
    for ref_et in @ref_ets
      adj_et = @pcm.adj_et({:ref_et => ref_et, :pct_cover => 0.0})
      assert_in_delta(expected_adj_ets[ii], adj_et, DELTA,"Wrong adjusted ET returned for ref ET #{ref_et} and 0.0 percent cover; expected #{expected_adj_ets[ii]} and was #{adj_et}")
      ii += 1
    end
  end
  
  test "Adj ET at and above 80% cover should equal reference ET" do
    percent_covers = [80.0, 81.0, 90.0, 99.9, 100.0]
    ref_et = 0.32
    expected_adj_ets = []
    percent_covers.each { |pc| expected_adj_ets << ref_et }
    ii = 0
    for percent_cover in percent_covers
      adj_et = @pcm.adj_et({:ref_et => ref_et, :pct_cover => percent_cover})
      assert_in_delta(expected_adj_ets[ii], adj_et, DELTA,"Wrong adjusted ET returned for ref ET #{ref_et} and 0.0 percent cover; expected #{expected_adj_ets[ii]} and was #{adj_et}")
    end
  end
  
  test "Midrange percent covers should agree" do
    percent_covers = [9.9, 10.0, 12.0, 34.0, 45.0, 56.0, 79.0, 79.9]
    ref_et = 0.32
    expected_adj_ets = [0.07326299, 0.073801, 0.0838014, 0.187592, 0.2312555, 0.2686298, 0.3182587, 0.31982587]
    ii = 0
    for percent_cover in percent_covers
      adj_et = @pcm.adj_et({:ref_et => ref_et, :pct_cover => percent_cover})
      assert_in_delta(expected_adj_ets[ii], adj_et, DELTA,"Wrong adjusted ET returned for ref ET #{ref_et} and #{percent_cover} percent cover; expected #{expected_adj_ets[ii]} and was #{adj_et}")
      ii += 1
    end
  end
  
  test "Midrange corn lai should agree" do
	days_since_emergences = [0,1,10,11,29,48,79,80,160]
	expected_lais = [0.0,0.0,0.00029509,0.00056963,0.20934018,1.71987480,4.06866074,4.06866610,0.33750846]
	for days_since_emergence in days_since_emergences
		lai = @pcm.calc_lai_corn({:days_since_emergence => days_since_emergence})
		assert_in_delta(expected_lais[ii],lai, DELTA, "Wrong LAI refurned for days_since_emergence #{days_since_emergence}; expected #{expected_lais[ii]} and was #{lai}")
	end
  end

  test "Midrange corn lai adjET should agree" do
	days_since_emergences = [0,1,10,11,29,48,79,80,160]
	ref_et = 0.32
	expected_adj_ets = [0.0,0.0,0.0,0.0,0.09,0.2,0.35,0.35,0.14]
	for days_since_emergence in days_since_emergences
		adj_et = @pcm.adj_et_lai_corn({:ref_et => ref_et, :days_since_emergence => days_since_emergence})
		assert_in_delta(expected_lais[ii],lai, DELTA, "Wrong adjusted ET refurned for days_since_emergence #{days_since_emergence}; expected #{expected_adj_ets[ii]} and was #{adj_et}")
	end
  end
end
