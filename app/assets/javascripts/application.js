//= require jquery
//= require jquery_ujs
//= require jquery-ui
//= require jqgrid-jquery-rails
//= require_tree .

if (typeof jQuery != 'undefined') {
  $(document).ajaxSend(function(event, request, settings) {
    if (typeof(AUTH_TOKEN) == "undefined") return;
    // settings.data is a serialized string like "foo=bar&baz=boink" (or null)
    settings.data = settings.data || "";
    settings.data += (settings.data ? "&" : "") + "authenticity_token=" + encodeURIComponent(AUTH_TOKEN);
  });
}
