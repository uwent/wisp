//= require jquery
//= require jquery_ujs
//= require jquery-ui
//= require turbolinks
//= require jqgrid-jquery-rails
//= require_tree .

function option(id,text) {
  return("<option value='"+id+"'>"+text+"</option>");
}

function add() {
  $('#multi_edit_link_weather_station_id option:selected').each(function(){
    opt = option($(this).attr("value"),$(this).text());
    $('#weather_station_field_ids').append(opt);
    $('#multi_edit_link_weather_station_id option:selected').remove();
  });
}

function addAll() {
  // just like add, except don't bother picking out the selected one(s)
  $('#multi_edit_link_weather_station_id option').each(function(){
    opt = option($(this).attr("value"),$(this).text());
    $('#weather_station_field_ids').append(opt);
    $(this).remove();
    // $('#multi_edit_link_weather_station_id option:selected').remove();
  });
}

function removeFromLeft() {
  // exactly the inverse of add()
  $('#weather_station_field_ids option:selected').each(function(){
    opt = option($(this).attr("value"),$(this).text());
    $('#multi_edit_link_weather_station_id').append(opt);
    $('#weather_station_field_ids option:selected').remove();
  });
}

function removeAll() {
  // same as remove(), except we don't bother with selected
  $('#weather_station_field_ids option').each(function(){
    opt = option($(this).attr("value"),$(this).text());
    $('#multi_edit_link_weather_station_id').append(opt);
    $(this).remove();
  });
}

function selectEverything() {
  $('#weather_station_field_ids option').each(function(){
    $(this).attr('selected',true);
  });
}

function clickIt() {
  form = $(this).parentsUntil('form');
  selectEverything();
  form.submit();
}

// double-click handler for adding
$('#multi_edit_link_weather_station_id option').on('dblclick',function(){
  add();
});

// and one for removing
$('#weather_station_field_ids option').on('dblclick',function(){
  removeFromLeft();
});

function fillProblemsBox(id) {
  $.ajax({
    type: "GET",
    url: "/farms/problems",
    dataType: 'html',
    async: false,
    success: function(newHtml) {
      // Set the HTML of the summary box to the new stuff
      $('#farmProblemsBox').html(newHtml);
    }
  });
}

function parseDate(input) {
  var parts = input.match(/(\d+)/g);
  return new Date(parts[0], parts[1]-1, parts[2]);
}
function dateToS(date) {
  return date.getFullYear() + '-' + (1+date.getMonth()) + '-' + date.getDate();
}
function setLastAndNextWeeks(date) {
  lastWeek = parseDate(date);
  lastWeek.setDate(lastWeek.getDate()-7);
  lastWeek = dateToS(lastWeek);
  nextWeek = parseDate(date);
  nextWeek.setDate(nextWeek.getDate()+7);
  nextWeek = dateToS(nextWeek);
}

// TODO: This won't work:
// <%= grid_javascript_settings %>
// var cur_date = '<%= @cur_date %>;'
var cur_date;
var lastWeek
var nextWeek;
setLastAndNextWeeks(cur_date);
var initial_date = '<%= @initial_date %>';
// Load the Visualization API and the piechart package.
google.load('visualization', '1.0', {'packages':['corechart']});

// We don't know why the Google Vis API suddenly started having a cow over
// our numbers. But this will reformat to fix it.
function td(num) {
  if (null === num || undefined === num) {
    return(0.0);
  }
  flt = parseFloat(num); // in case it's a string
  return(parseFloat(num.toPrecision(2)));
}
function array_min(arr) {
  min = 10000.0;
  for (var ii = arr.length - 1; ii >= 0; ii--){
    if (arr[ii] < min) {
      min = arr[ii];
    }
  };
  return(min);
}
// Calculate a baseline for the graph. Easy if they're not going into negative-AD territory!
function baseLine(ad_data,prj_data) {
  if (prj_data) {
    smallest = array_min(ad_data.concat(prj_data));
  } else {
    smallest = array_min(ad_data);
  }
  if (smallest >= 0.0) {
    smallest = 0.0;
  } else {
    // drop the baseline to a skosh below the lowest point
    smallest = Math.floor(smallest - 0.20);
  }
  return smallest;
}
// Callback that creates and populates a data table,
// instantiates the chart, passes in the data and
// draws it.
function plotGraph() {
  var ad_data = null;
  var prj_data = null;
  var targ_data = null;
  var labels = null;

  url = '/wisp/projection_data?cur_date=&field_id='; // TODO: cur_date and field_id
  // TODO: This won't work:
  // ad_max = td(<%= @field.ad_max %>);
  ad_min = 0.0;
  $.ajax(
  {
    type: "GET",
    url: url,
    dataType: "json",
    async: false,
    success: function(json)
    {
     ad_data = json['ad_data'];
     prj_data = json['projected_ad_data'];
     targ_data = json['target_ad_data'];
     labels = json['labels'];
    }
  });

   // Create the data table.
   // Field Capacity, AD, [Target], [Projected], 0.0 AD
   var data = new google.visualization.DataTable();
   data.addColumn('string', 'Date');
   data.addColumn('number', 'Field capacity');
   data.addColumn({type: 'string', role: 'annotation'});
   data.addColumn('number', 'Daily AD (in.)');
   data.addColumn({type: 'boolean', role: 'certainty'});
   data.addColumn({type: 'string', role: 'annotation'});
   data.addColumn('number', 'Depleted');
   data.addColumn({type: 'string', role: 'annotation'});
   if (targ_data) {
     data.addColumn('number', 'Target');
     data.addColumn({type: 'string', role: 'annotation'});
   }
   var colors = ['#555555','#0000FF','#FF0000','#00AA00']; // FC gray, AD blue, AD==0 line red [, target green]
   ad_len = ad_data.length;
   wsc_anno = [];
   targ_anno = [];
   depl_anno = [];
   for (var ii=0; ii < ad_len; ii++) {
     wsc_anno[ii] = '';
     targ_anno[ii] = '';
     depl_anno[ii] = '';
   };
   wsc_anno[0] = "Field capacity";
   targ_anno[ad_len-2] = 'Target AD';
   depl_anno[0] = 'Depleted';
   // first_projected is set to be false for the second and subsequent points of any series of
   // projected data. So only the first one gets labeled "Projected", but if there's another series of
   // them (as weird as that would be for actual data), the first one there gets labeled too.
   for (var ii=0,first_projected = true; ii<ad_len; ii++) {
     label = labels[ii];
     row = [];
     // Projected? prj_data is an array 1-for-1 w/ad_data -- true if projected, false if "real"
     projected_anno = '';
     if (prj_data[ii]) {
       is_solid_ad_line = false;
       if (first_projected) {
         projected_anno = 'Projected'; // label this one
         first_projected = false;  // but ensure subsequent ones aren't
       }
     } else {
       is_solid_ad_line = true;
       first_projected = true; // ready for the next start of a projection series
     }
     row = [label,ad_max,wsc_anno[ii],td(ad_data[ii]),is_solid_ad_line,projected_anno,ad_min,depl_anno[ii]];
     if (targ_data) {
       row[row.length] = td(targ_data[ii]); // Tack on target if it's present
       row[row.length] = targ_anno[ii];
     }
     data.addRow(row);
   }

   if (targ_data) {
     // target line present
     series = {0:{lineWidth:8,areaOpacity:0.2,visibleInLegend:false},1:{pointSize:15},2:{lineWidth:8,visibleInLegend:false},3:{areaOpacity:0,visibleInLegend:false}};
   } else {
     series = {0:{lineWidth:8,areaOpacity:0.2,visibleInLegend:false},1:{pointSize:15},2:{lineWidth:8,visibleInLegend:false}};
   }
   // Set chart options
   if (projected_anno == 'Projected') {
     title = 'Calculated / Projected Allowable Depletion (inches)';
   } else {
     title = 'Calculated Allowable Depletion (inches)';
   }
   var options = {'title':title,
                  'width':646,
                  'height':290,
                  'colors':colors,
                  'fontSize':12,
                  'pointSize':0,
                  'titleTextStyle':{fontSize:18},
                  'series':series,
                  // Set vertical axis range to run between fudge-factored values to make the annotations show nicely
                  'vAxis': {baseline:baseLine(ad_data,prj_data),maxValue:Math.ceil(ad_max + 0.2)},
                  'annotation':{style:'line'}
                 };

   // Instantiate and draw our chart, passing in some options.
   var chart = new google.visualization.AreaChart(document.getElementById('graphBox'));
   chart.draw(data, options);
 }

function curPage(initial_date_str,cur_date_str) {
  initial_date_obj = parseDate(initial_date_str);
  // set the global
  cur_date = cur_date_str;
  cur_date_obj = parseDate(cur_date_str);
  days = (cur_date_obj.getTime() - initial_date_obj.getTime()) / (86400 * 1000);
  return(Math.ceil(days / 7));
}
function showSummaryBox(date) {
  $.ajax(
    {
      type: "GET",
      url: "/wisp/summary_box?cur_date=" + date, // TODO: field_id
      dataType: 'html',
      async: false,
      success: function(newHtml)
      {
        // Set the HTML of the summary box to the new stuff
        $('#projectedADBox').html(newHtml);
      }
    });
}
function showTargetAD() {
  // adValue = 0.0;
  // TODO: This won't work.
  // adValue = <%= @field.target_ad_pct || "''".html_safe %>;
  document.getElementById('target_ad').value = adValue;
}

function changeDate(newDate) {
  /* Detect if the passed-in object is coming from the calendar's "change" event, or
     passed in explicitly by one of our button handlers */
  if (newDate.type == "change") {
    cur_date = $('#date_input').val();
  } else {
    cur_date = newDate;
    $('#date_input').val(cur_date);
  }
  setLastAndNextWeeks(cur_date);
  cur_page = curPage(initial_date,cur_date);
  $("#weather").setGridParam({ page: cur_page }).trigger("reloadGrid");
  plotGraph();
  showSummaryBox(cur_date);
}

function hoverColor(id,hover) {
  if (hover)
    $(id).css({'background-color':'blue','color':'white'});
  else
    $(id).css({'background-color':'#DDD','color':'black'});
  }

jQuery(document).ready(function(){
  plotGraph();
  showSummaryBox(cur_date);
  showTargetAD();
  $("#date_input").change(changeDate);
});

if (typeof jQuery != 'undefined') {
  $(document).ajaxSend(function(event, request, settings) {
    if (typeof(AUTH_TOKEN) == "undefined") return;
    // settings.data is a serialized string like "foo=bar&baz=boink" (or null)
    settings.data = settings.data || "";
    settings.data += (settings.data ? "&" : "") + "authenticity_token=" + encodeURIComponent(AUTH_TOKEN);
  });
}
