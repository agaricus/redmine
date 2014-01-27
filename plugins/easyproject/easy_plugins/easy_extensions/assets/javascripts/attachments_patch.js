window.addInputFiles = function(inputEl) {
    var clearedFileInput = $(inputEl).clone().val('');

    if (inputEl.files && window.FileReader) {
        // upload files using ajax
        uploadAndAttachFiles(inputEl.files, inputEl);
        $(inputEl).remove();
    } else {
        // browser not supporting the file API, upload on form submission
        var attachmentId;
        var aFilename = inputEl.value.split(/\/|\\/);
        attachmentId = addFile(inputEl, {
            name: aFilename[ aFilename.length - 1 ]
        }, false);
        if (attachmentId) {
            $(inputEl).attr({
                name: 'attachments[' + attachmentId + '][file]',
                style: 'display:none;'
            }).appendTo('#attachments_' + attachmentId);
        }
    }
    $(".attachments-container > .add_attachment").prepend(clearedFileInput);
}

window.addFile = function(inputEl, file, eagerUpload) {

    if ($('#attachments_fields').children().length < 10) {

        var attachmentId = addFile.nextAttachmentId++;

        var fileSpan = $('<span>', {
            id: 'attachments_' + attachmentId
        });

        fileSpan.append($('<input>', {
            type: 'text',
            'class': 'filename readonly ' + ($(inputEl).data('description-is') ? 'half' : 'full'),
            name: 'attachments[' + attachmentId + '][filename]',
            readonly: 'readonly'
        } ).val(file.name));
        if ($(inputEl).data('description-is')) {
            fileSpan.append($('<input>', {
                type: 'text',
                'class': 'description',
                name: 'attachments[' + attachmentId + '][description]',
                maxlength: 255,
                placeholder: $(inputEl).data('description-placeholder'),
                required: $(inputEl).data('description-is-required')
            } ).toggle(!eagerUpload));
        };
        fileSpan.append($('<a>&nbsp</a>').attr({
            href: "#",
            'class': 'remove-upload'
        }).click(removeFile).toggle(!eagerUpload));

        fileSpan.appendTo('#attachments_fields');

        if(eagerUpload) {
            ajaxUpload(file, attachmentId, fileSpan, inputEl);
        }

        return attachmentId;
    }
    return null;
}
addFile.nextAttachmentId = 1;

window.handleFileDropEvent = function(e) {
    if (typeof(e.dataTransfer) == 'undefined') return;
    $(this).removeClass('fileover');
    blockEventPropagation(e);

    if ($.inArray('Files', e.dataTransfer.types) > -1) {
        uploadAndAttachFiles(e.dataTransfer.files, $('input:file.file_selector'));
    }
}

window.setupFileDrop = function() {
    if (window.File && window.FileList && window.ProgressEvent && window.FormData && window.FileReader) {

        $.event.fixHooks.drop = {
            props: [ 'dataTransfer' ]
        };

        $('form div.box').has('input:file').each(function() {
            $(this).on({
                dragover: dragOverHandler,
                dragleave: dragOutHandler,
                drop: handleFileDropEvent
            });
        });
    }
}

function unbindSetupFileDrop() {
    if (!window.FileReader) {
        $('form div.box').has('input:file').each(function() {
            $(this).off("dragover");
            $(this).off("dragleave");
            $(this).off("drop");
        })
    }
};

$(document).ready(unbindSetupFileDrop);