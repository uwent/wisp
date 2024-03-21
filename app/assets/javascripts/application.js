//= require jquery
//= require jquery_ujs
//= require jquery-ui
//= require jqgrid-jquery-rails
//= require_tree .

// remove params from URL after page load
$(() => {
  window.history.replaceState(null, null, window.location.pathname)
});

function escapeHTML(unsafe) {
  return unsafe
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}
