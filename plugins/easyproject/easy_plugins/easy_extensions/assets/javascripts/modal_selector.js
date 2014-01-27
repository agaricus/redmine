//var dhxWins, w1;
var modal_selector_ctx_menu;
var additional_infinitescroll_path;

function addSelectedValueInModalSelector(container_id, internal_id, display_value, display_value_escaped, field_name, field_id) {
    var new_easy_lookup_selected_value_wrapper = $("<span>").attr({
        'class' : 'easy-lookup-selected-value-wrapper easy-lookup-' + field_id + '-' + internal_id + '-wrapper'
    });
    var new_hidden_id = $('<input />').attr({
        'type' :'hidden',
        'value' : internal_id,
        'name' : field_name,
        'class' : 'serializable-' + field_id
    });
    var new_display_name = $("<span>").attr({
        'class' : 'display-name'
    }).html(display_value);
    var new_dont_copy =$("<span>").attr({
        'class' : 'dont-copy'
    });
    var new_other_delete =$("<a>").attr({
        'href' : 'javascript:removeSelectedModalEntity(\'.modal-selected-values .easy-lookup-' + field_id + '-' + internal_id + '-wrapper\', \'entity-' + internal_id +'\');',
        'class' : 'icon icon-del'
    });

    var selected_values_container = $('#' + container_id + '-modal-selected-values-container');

    new_easy_lookup_selected_value_wrapper.append(new_hidden_id);
    new_easy_lookup_selected_value_wrapper.append(new_display_name);
    new_dont_copy.append(new_other_delete);
    new_easy_lookup_selected_value_wrapper.append(new_dont_copy);
    selected_values_container.append(new_easy_lookup_selected_value_wrapper);
}

function removeSelectedModalEntity(selector, tr_id) {
    $(selector).remove();;
    var tr = $('#' + tr_id);
    if (tr.length == 0) {
        console.log('tady to nedopadne dobre');
        tr = $('#' + modal_selector_ctx_menu.uniq_prefix + tr_id);
    }
    if (tr.length > 0) {
        contextMenuRemoveSelection(tr);
    }
}

function changeModalSelectorValue(container_id, cbx_id, display_value_id, display_escaped_value_id, field_name, field_id, multiple) {
    var cbx = $("#" + cbx_id);
    var old_selected_values = $('.modal-selected-values .easy-lookup-' + field_id + '-' + cbx.val() + '-wrapper');
    if (!multiple && cbx.is(":checked")) {
        $('.modal-selected-values .easy-lookup-selected-value-wrapper').remove();
    }
    if (old_selected_values.length == 0 && cbx.is(":checked")) {
        addSelectedValueInModalSelector(container_id, cbx.val(), $("#" + display_value_id).val(), $("#" + display_escaped_value_id).val(), field_name, field_id);
    } else if (old_selected_values.length > 0 && !cbx.is(":checked")) {
        old_selected_values.remove();
    }
}

function toggleModalSelectorSelection(el) {
    var boxes = el.find('input[type=checkbox]');
    var all_checked = true;
    boxes.each(function(i) {
        if (!$(this).is(":checked")) {
            all_checked = false;
        }
    })
    boxes.each(function(i) {
        if (all_checked) {
            boxes[i].checked = false;
            boxes[i].onchange(null);
            $(this).parents('tr').removeClass('context-menu-selection');
        } else if (boxes[i].checked == false) {
            boxes[i].checked = true;
            boxes[i].onchange(null);
            $(this).parents('tr').addClass('context-menu-selection');
        }
    })
}

function copyInnerHTML(source_id, target_id) {
    $("#" + target_id).html($("#" + source_id).html());
}

function copySelectedModalEntities(source_id, target_id) {
    copyInnerHTML(source_id, target_id);
    $("#" + target_id + " .dont-copy").remove();
    // if empty ( no value )
    if( $("#" + target_id ).html().match(/^\s*$/) ) {
        $("#" + target_id ).html($("#" + target_id + "-no_value" ).clone().show() );
    }
}

function createModalSelectorWindow(width) {
    showModal('modal-dialog-loader-wrapper', width || '70%');
}

function closeModalSelectorWindow(ele) {
    hideModal($('#modal-dialog-loader'));
    additional_infinitescroll_path = null;
    unbindInfiniteScrollModalSelector();
    if (ele)   {
        window.location.reload();
    }
    $('#modal-dialog-loader').html("");
    $('#modal-dialog-loader-wrapper').attr('style', 'display:none');
}

function showModalSelectorWindow(pathParse) {
    createModalSelectorWindow();
    additional_infinitescroll_path = pathParse;
    bindInfiniteScrollModalSelector();
}

function showFullscreen(element_id, label_close, title_close) {
    source = $('#'+element_id);
    // $.data(source[0], 'oldCss', source.attr("style"));
    $("body").append($("<div style='position:fixed;top:0;left:0;width:100%;height:100%;background:#fff' id='fullscreen-background-cover'></div>"));
    source.css({
        'position':'absolute',
        'top': '10px',
        'left': '0',
        'width': '100%',
        'height': '100%',
        'z-index': 10000,
        'background-color': '#fff'
    });
    $("#footer, #header, #indent-box").hide();

    source.append(addFullscreenCloseButton(label_close, title_close, 'fullscreen-close', element_id));

}

function addFullscreenCloseButton(label, title, container_id, element_id) {
    var a = $("<a href=\"javascript:closeFullscreen('"+ element_id +"', '" + container_id +"')\">");

    a.attr({
        'title': title,
        'id' : 'modal-selector-close-button',
        'class' : 'button-2'
    });
    a.html(label);

    return $("<div id='" + container_id + "' class='modal-close-button'></div>").css({'position': 'fixed', 'top' : 0, 'right': 0, 'z-index' : '10001'}).html(a);
}

function closeFullscreen(element_id, close_button_container) {
    $("#footer, #header, #indent-box").show();
    $("#"+close_button_container).remove();
    $("#fullscreen-background-cover").remove();
    source = $('#'+element_id);
    source.removeAttr("style");
}

function saveAndCloseModalSelectorWindow(field_id) {
    if (eval("typeof beforeCloseModalSelectorWindow_" + field_id) == 'function') {
        eval('beforeCloseModalSelectorWindow_' + field_id + '();');
    }
    else
    {
        copySelectedModalEntities(field_id + '-modal-selected-values-container', field_id);
    }

    closeModalSelectorWindow();

    if (eval("typeof afterCloseModalSelectorWindow_" + field_id) == 'function') {
        eval('afterCloseModalSelectorWindow_' + field_id + '();');
    }
}

function bindInfiniteScrollModalSelector(pathParse) {
    $.extend($.infinitescroll.defaults.loading, {
        selector: '#modal-selector-easy-autoscroll',
        binder: $('#modal-selector-easy-autoscroll'),
        msgText: '',
        finishedMsg: '',
        localMode: true
    });
    $('#modal-dialog-loader table.list.modal-selector-entities:first > tbody').infinitescroll({
        navSelector: '#modal-dialog-loader p.pagination',
        nextSelector: '#modal-dialog-loader p.pagination > a.next',
        itemSelector: 'tr.easy-query-modal-selector-row-item',
        binder: $('#modal-selector-easy-autoscroll'),
        behavior: 'modal_selector',
        pathParse: pathParse || additional_infinitescroll_path,
        localMode: true,
        loading: {
            selector: '#modal-selector-easy-autoscroll',
            binder: $('#modal-selector-easy-autoscroll'),
            msgText: '',
            finishedMsg: ''
        }
    });
}

function unbindInfiniteScrollModalSelector() {
    $('table.list.modal-selector-entities:first > tbody').infinitescroll('unbind');
}

function freeTextSearch(url, element, type) {
    $.ajax({
        url: url,
        type: type,
        data: $('.modal-selected-values form, input#easy_query_q, #freetext_reset').serialize()
    }).done(function(data) {
        bindInfiniteScrollModalSelector(function() {
            return [url + '&' + $('#modal_selector_query_form, .modal-selected-values form').serialize() + '&page=', ''];
        });
        $("#modal-dialog-loader").html(data);
        $('.easy-query-heading .buttons').hide();
        $(element).focus();
    })
}

function selectAllOptions(id)
{
    var select = $('#'+id);
    select.children('option').attr('selected', true);
}
$(function() {
    $.infinitescroll.prototype._nearbottom_modal_selector = function() {
        var opts = this.options;
        return 0.9 < ((opts.binder.scrollTop() + opts.binder.height()) / $(opts.contentSelector).height());
    };
});
