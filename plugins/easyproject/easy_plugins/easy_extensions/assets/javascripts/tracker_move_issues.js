$(document).ready(function() {
    $("#tracker_to_id").change();
});

window.loadCustomFieldMapping = function(url, trackerToInput) {
    $('#custom-field-mapping-fs').hide();
    $('#custom_field_mapping').empty();
    if(!$(trackerToInput).val()) return;

    loading();

    $('#custom-field-mapping').load(url + '?tracker_to_id=' + $(trackerToInput).val(), function() {
        $('#custom-field-mapping-fs').show();
        loading();
    });
};

function loading() {
    $('#ajax-indicator').toggle();
}
