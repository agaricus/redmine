function workingPlanSubmit(button, url, issue_id) {
  button = $(button);
  $.post(url, button.closest('tr.issue_'+issue_id).find('input').serialize(), function(response) {
    if (response.type != 'error') {
      button.closest('tr.issue_'+issue_id).find('input').attr('disabled', true);
      button.remove();
      location.reload();
    }
    $('div.resalloc-flash').remove();
    var fl = $('<div/>').addClass('flash resalloc-flash').addClass(response.type).append($('<span/>').html(response.html)).insertBefore('.user-allocation-plan');
    setTimeout(function() {
      fl.fadeOut('slow', function() {fl.remove()});
    }, 4000);
    for (day=0;day <= 5; day++) {
      i = 0;
      $('.plan-hour.'+day+' input').each( function() {i = i + parseFloat($(this).val()|| 0)});
      $('tfoot .plan-hour.'+day).html(i);
    };
  })
}
function workingPlanOnChange(self, issue_id, url) {
  var tr = $(self).closest('tr.issue_'+issue_id)
  $.post(url, tr.find('input').serialize(), function(response) {
    tr.find("input#data_"+issue_id+"_start").val(response.users[0].entities[0].start);
    tr.find("input#data_"+issue_id+"_end").val(response.users[0].entities[0].end);
  })
}