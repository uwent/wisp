module AwonHelper
  
  def title
    "Automated Weather Observation Stations"
  end
  def do_welcome
    image_tag("awon.jpg",{:width => "231", :height => "347", :alt => "weather station"}) + 
      "<h2>" +
      link_to(title, :action => "index") +
      "</h2>"
  end
  
  def date_selector_section
    str = <<-END
    END
    str
  end
  
  def station_selector_section
    <<-END
    <select Name="station" SIZE=4 id="station_selector">
      <option value="4781" SELECTED>4781 1985-01-01 to present Arlington</option>
      <option value="4751">4751 1985-01-01 to present Hancock&nbsp;</option>
      <option value="4773">4773 2001-10-17 to present Spring Green&nbsp;</option>
      <option value="4756">4756 2005-12-09 to 2006-07-24 Marshfield&nbsp;</option>
      <option value="4731">4731 1985-01-01 1998-10-03 Antigo&nbsp;</option>
      <option value="4742">4742 1992-06-24 1997-01-23 Arkansaw&nbsp;&nbsp;</option>
      <option value="4713">4713 1985-01-01 1998-11-09 Chetek&nbsp;</option>
      <option value="4752">4752 1991-01-01 1998-12-22 Cranmoor&nbsp;</option>
      <option value="4791">4791 1990-04-21 1998-01-01 Elkhorn&nbsp;</option>
      <option value="4762">4762 1993-10-22 1996-09-10 Greenleaf&nbsp;</option>
      <option value="4750">4750 1997-07-24 1997-08-04 Hancock (old)&nbsp;</option>
      <option value="4782">4782 1985-01-01 1992-11-19 Janesville&nbsp;</option>
      <option value="4771">4771 1986-01-01 1997-04-03 Lancaster&nbsp;</option>
      <option value="4783">4783 1992-01-15 1998-04-30 Madison&nbsp;</option>
      <option value="4722">4722 1996-06-12 1998-10-26 Manitowish&nbsp;</option>
    	<option value="4755">4755 1993-07-09 1997-03-20 Marshfield (old)&nbsp;</option>
    	<option value="4743">4743 1993-12-31 1995-08-31 Maxville&nbsp;</option>
      <option value="4774">4774 1990-07-24 1992-12-30 Muscoda&nbsp;</option>
      <option value="4754">4754 1992-06-24 1995-10-15 Nekoosa&nbsp;</option>
      <option value="4763">4763 1994-05-02 1998-12-16 Pickett&nbsp;</option>
      <option value="4772">4772 1986-01-01 1998-01-01 Prairie du Sac&nbsp;</option>
      <option value="4773">4773 1989-01-01 1998-10-17 Spring Green&nbsp;</option>
      <option value="4761">4761 1992-04-10 1997-06-30 Sturgeon Bay&nbsp;</option>
      <option value="4780">4780 1993-12-31 1996-06-27 Verona&nbsp;</option>
      <option value="4753">4753 1991-01-01 1992-12-30 Warrens&nbsp;</option>
      <option value="4721">4721 1990-07-02 1998-01-01 Woodruff&nbsp;</option>
    </select>
    END
  end
  
  def status_boldness(stn)
    boldness = (stn.status == 'T' ? 'bold' : 'normal')
    "<span style='font-weight: #{boldness}'>"
  end
end
