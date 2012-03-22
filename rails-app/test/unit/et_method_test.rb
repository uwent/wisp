require 'test_helper'

class EtMethodTest < ActiveSupport::TestCase
  DELTA = 0.00001 # delta for floating-point equality tests
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
    assert_nothing_raised(Exception) { @adjET = @pcm.adj_et_pct_cover(@refET,@pctCover)}
    assert(@adjET, "Should have calculated an adjusted ET")
  end
  
  test "can polymorphically call adjET" do
    assert_nothing_raised(Exception) { @pcm.adj_et({:ref_et => @refET, :pct_cover => @pctCover}) }
  end
  
  test "adjusted ET for zero ref ET and zero pct cover" do
    assert_equal(0.0, @pcm.adj_et({:ref_et => 0.0, :pct_cover => 0.0}))
  end
  
  test "adjusted ET with zero percent cover" do
    expected_adj_ets = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
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
    # Pair up a day-since-emergence with the expected LAI for that day
    expected_lais_for_day = {
      0 => 0.0, 1 => 0.0, 10 => 0.00029509,
      11 => 0.00056963, 29 => 0.20934018,
      48 => 1.71987480, 79 => 4.06866074,
      100 => 3.245620, 160 => 0.33750846
    }
    expected_lais_for_day.each do |day,expected_lai|
      lai = @pcm.lai_corn(day)
      assert_in_delta(expected_lai,lai, DELTA, "Wrong LAI refurned for days_since_emergence #{day}; expected #{expected_lai} and was #{lai}")
    end
  end

  def run_corn_lai_adj_et_test(ref_et,expected_adj_ets_for_day)
    # Pair up a day-since-emergence with the expected crop/adjusted ET for that day
    expected_adj_ets_for_day.each do |day,expected_adj_et|
      adj_et = @pcm.adj_et_lai_corn(ref_et, day)
      assert_in_delta(expected_adj_et,adj_et, DELTA, "Wrong adjusted ET returned for days_since_emergence #{day}; expected #{expected_adj_et} and was #{adj_et}")
    end
  end
  
  test "Corn lai adjET should agree when high ET" do
    ref_et = 0.32
    expected_adj_ets_for_day = {
      # These numbers are straight out of John's spreadsheet -- just pegged the
      # "AWON Reference ET (in/day)" column all the way down
      0 => 0.0, 1 => 0.0, 10 => 0.000156, 11 => 0.000301, 
      29 => 0.094860, 48 => 0.325323, 79 => 0.351213, 
      100 => 0.349295, 160 => 0.139834
    }
    run_corn_lai_adj_et_test(ref_et,expected_adj_ets_for_day)
  end

  test "Corn lai adjET should agree when low ET" do
    ref_et = 0.01
    expected_adj_ets_for_day = {
      # Numbers out of spreadsheet as before
      0 => 0.0, 10 => 0.000005, 30 => 0.003417,
      60 => 0.010887, 100 => 0.010915,
      160 => 0.004370
    }
    run_corn_lai_adj_et_test(ref_et,expected_adj_ets_for_day)
  end
  

  test "I can get entered percent covers" do
    wx = [{:entered_pct_cover => 0}, {},{:entered_pct_cover => nil},{:entered_pct_cover => 20.0},{:entered_pct_cover => nil}]
    assert((found = @pcm.surrounding(wx,2,:entered_pct_cover)),"Should have returned something from surrounding")
    assert_equal(Array, found.class)
    assert_equal(2, found.size)
  end
 
  def interp(arr,start,finish)
    @pcm.linear_interpolation(arr,start,finish,:entered_pct_cover,:calculated_pct_cover)
  end
  
  test "empty wx arr and ones with no pct covers entered are unchanged by interpolation" do
    wx = []
    interp(wx,0,0)
    assert_equal([], wx)
    wx = [{:calculated_pct_cover => 0.0}, {:calculated_pct_cover => 10.0}, {:calculated_pct_cover => 30.0}]
    wx_2 = wx.clone
    assert_equal(wx_2, wx)
    interp(wx,0,2)
    assert_equal(wx_2, wx)
  end
  
  test "linear_increment works" do
    li = @pcm.linear_increment(0.0,4.0,5.0)
    assert_in_delta(1.0, li, 0.00001)
    li = @pcm.linear_increment(0,4,5)
    assert_in_delta(1.0, li, 0.00001)
  end
  
  test "linear interpolation works on two entered points" do
    wx =  [{:calculated_pct_cover => 12.0},
          {:calculated_pct_cover => 1.0, :entered_pct_cover => 1.0},
          {:calculated_pct_cover => 3.0},
          {:calculated_pct_cover => 3.0},
          {:calculated_pct_cover => 3.0},
          {:calculated_pct_cover => 3.0, :entered_pct_cover => 5.0},
          {:calculated_pct_cover => 30.0, :entered_pct_cover => 100.0}
    ]
    interp(wx,1,5)
    expected = [12.0,1.0,2.0,3.0,4.0,5.0,30.0]
    ii = 0
    wx.each { |w| assert_equal(expected[ii], w[:calculated_pct_cover],"wrong number on #{ii}th day"); ii+=1 }
  end
  
  test "linear interpolation works on many entered points, down as well as up" do
    wx =  [{:calculated_pct_cover => 12.0},
          {:calculated_pct_cover => 1.0, :entered_pct_cover => 1.0},
          {:calculated_pct_cover => nil},
          {:calculated_pct_cover => nil},
          {:calculated_pct_cover => nil},
          {:calculated_pct_cover => 3.0, :entered_pct_cover => 5.0},
          {:calculated_pct_cover => nil},
          {:calculated_pct_cover => nil},
          {:calculated_pct_cover => nil},
          {:calculated_pct_cover => nil, :entered_pct_cover => 1.0},
          {:calculated_pct_cover => nil},
          {:calculated_pct_cover => nil, :entered_pct_cover => 0.0}
    ]
    interp(wx,1,5)
    interp(wx,5,9)
    expected = [12.0,1.0,2.0,3.0,4.0,5.0,4.0,3.0,2.0,1.0,0.5,0.0,nil,0.0]
    ii = 0
    wx.each { |w| assert_in_delta(expected[ii], wx[ii][:calculated_pct_cover],0.00001,"for the #{ii}th value")}
  end
  
  class Wx < Hash
    attr_accessor :saved
    def save!
      @saved = true
    end
  end
  
  test "ensure save! works" do
    w = Wx.new
    w.save!
    assert(w.saved, "Should have saved it")
  end
    
  test "save gets called when we interpolate" do
    wx = []
    0.upto(2) do |ii|
      w = Wx.new
      w[:entered_pct_cover] = 0.0
      wx << w
    end
    interp(wx,0,2)
    wx.each { |w| assert(w.saved, "Should have been saved") }
  end
  
  test "surrounding works" do
    wx = []
    res = nil
    assert_nothing_raised(Exception) { res = @pcm.surrounding(wx,4,:foo)}
    assert_nil(res)
    wx = [{:foo => 10.0}]
    assert_nil(@pcm.surrounding(wx,0,:foo))
    wx << {:foo => 20.0}
    assert_nil(@pcm.surrounding(wx,0,:foo))
    wx = [{:foo => 5.0}] + wx
    assert_equal([0,2], @pcm.surrounding(wx,1,:foo))
    wx = [{:foo => nil}, {:foo => 0.0}, {:foo => nil}, {:foo => 0.0}, {:foo => 0.0}, {:foo => nil}]
    assert_equal([1,3], @pcm.surrounding(wx,2,:foo))
  end
end
