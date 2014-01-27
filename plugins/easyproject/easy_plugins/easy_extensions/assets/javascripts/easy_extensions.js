var sidebarToggler = false;
function add_filter(modul_uniq_id) {
    select = $('#' + modul_uniq_id + 'add_filter_select');
    field = select.val();
    $('[id="' + modul_uniq_id + 'tr_' + field + '"]').show();
    $('[id="' + modul_uniq_id + 'cb_' + field + '"]').attr('checked', 'checked');
    toggle_filter(field, modul_uniq_id);
    select.selectedIndex = 0;
    $("option[value='" + field + "']", select).attr('disabled', 'disabled');
}

function toggle_filter(field, modul_uniq_id) {
    check_box = $('#' + modul_uniq_id + 'cb_' + field);

    if (check_box.is(':checked')) {
        $('#' + modul_uniq_id + "operators_" + field).show();
        toggle_operator(field, modul_uniq_id);
    } else {
        $('#' + modul_uniq_id + "operators_" + field).hide();
        $('#' + modul_uniq_id + "div_values_" + field).hide();
    }
}

function enableValues(field, indexes, modul_uniq_id) {
    var f;
    if (modul_uniq_id) {
        f = $("." + modul_uniq_id + ".values_" + field);
    } else {
        f = $(".values_" + field);
    }
    f.each(function(i) {
        if (indexes.indexOf(i) > -1) {
            $(this).removeAttr('disabled').parent('span').show();
        } else {
            $(this).attr('disabled', 'disabled').val('').parent('span').hide();
        }
    });
    if (indexes.length > 0) {
        $('#' + modul_uniq_id + "div_values_" + field).show();
    } else {
        $('#' + modul_uniq_id + "div_values_" + field).hide();
    }
}

function toggle_operator(field, modul_uniq_id) {
    operator = $('#' + modul_uniq_id + "operators_" + field);
    if (operator.val() == 'undefined') {
        $('#' + modul_uniq_id + "div_values_" + field).show();
    } else {
        switch (operator.val()) {
            case "!*":
            case "*":
            case "t":
            case "ld":
            case "w":
            case "lw":
            case "l2w":
            case "m":
            case "lm":
            case "y":
            case "o":
            case "c":
                enableValues(field, [], modul_uniq_id);
                break;
            case "><":
                enableValues(field, [0, 1], modul_uniq_id);
                break;
            case "<t+":
            case ">t+":
            case "><t+":
            case "t+":
            case ">t-":
            case "<t-":
            case "><t-":
            case "t-":
                enableValues(field, [2], modul_uniq_id);
                break;
            case "=p":
            case "=!p":
            case "!p":
                enableValues(field, [1], modul_uniq_id);
                break;
            default:
                enableValues(field, [0], modul_uniq_id);
                break;
        }
    }
}

function getEasyQueryFilterValue(filter_value_element) {
    var filter_value = '',
        val_el_val = [];

    if (filter_value_element.length > 0) {
        if (filter_value_element[0].tagName == 'SPAN') {
            filter_value_element.find('input[type="hidden"]').each(function(i, el) {
                val_el_val.push($(el).val());
            });
        } else {
            filter_value_element.each(function () {
                val_el_val.push($(this).val());
            });
        }
        filter_value = val_el_val.join('|');
    }
    return filter_value;
}

function getEasyQueryFiltersForURL(modul_uniq_id) {
    var filter_values = [];
    $('#' + modul_uniq_id + 'filters table.filters-table input:checkbox[name="fields[]"][checked="checked"]').each(function(idx, el) {
        var filter_value = ''
        var el_val = el.value.replace('.', '\\.');
        var operator = $('#' + modul_uniq_id + 'operators_' + el_val).val();
        var val_el_single_value = $('[name="values[' + el_val + '][]"]', $(el).closest('tr').children('td:last'));
        var val_el_two_values_1 = $('#' + modul_uniq_id + 'values_' + el_val + '_1');
        var val_el_two_values_2 = $('#' + modul_uniq_id + 'values_' + el_val + '_2');

        if (['=', '!', 'o', 'c', '*', '!*', '~', '!~'].indexOf(operator) >= 0 && val_el_single_value.length > 0) {
            filter_value = getEasyQueryFilterValue(val_el_single_value);
        } else if (['=', '>=', '<=', '><', '!*', '*'].indexOf(operator) >= 0 && val_el_two_values_1.length > 0 && val_el_two_values_2.length > 0) {
            filter_value = getEasyQueryFilterValue(val_el_two_values_1);
            filter_value += '|' + getEasyQueryFilterValue(val_el_two_values_2);
        } else if (operator == '') {
            var p1 = $('#' + modul_uniq_id + '' + el_val + '_date_period_1');
            if (p1 && p1.is(':checked')) {
                filter_value = $('#' + modul_uniq_id + 'values_' + el_val + '_period').val();
            }
            var p2 = $('#' + modul_uniq_id + '' + el_val + '_date_period_2');
            if (p2 && p2.is(':checked')) {
                filter_value = $('#' + modul_uniq_id + '' + el_val + '_from').val();
                filter_value += '|' + $('#' + modul_uniq_id + '' + el_val + '_to').val();
            }
        }

        filter_values.push(el.value + '=' + encodeURIComponent(operator + filter_value));
    })
    selectAllOptions(modul_uniq_id + 'selected_columns');
    if ($('#selected_project_columns').length > 0)
        selectAllOptions(modul_uniq_id + 'selected_project_columns');
    filter_values.push($('#' + modul_uniq_id + 'selected_columns').serialize());
    filter_values.push($('#' + modul_uniq_id + 'group_by').serialize());
    filter_values.push($('select.serialize, input.serialize', $('#' + modul_uniq_id + 'filters').closest('form')).serialize());
    // TODO razeni

    return filter_values.join('&');
}

function applyEasyQueryFilters(url, modul_uniq_id, additional_elements_to_serialize) {
    if (url.indexOf('?') >= 0) {
        url += '&'
    } else {
        url += '?'
    }

    var target_url = url + getEasyQueryFiltersForURL(modul_uniq_id);

    if (additional_elements_to_serialize && (additional_elements_to_serialize instanceof jQuery)) {
        target_url += '&' + additional_elements_to_serialize.serialize();
    }

    window.location = target_url;
}

function toggle_multi_select(field, modul_uniq_id) {
    ToggleMultiSelect(modul_uniq_id + 'values_' + field);
}

function ToggleMultiSelect(select_id, size) {
    if (typeof event != 'undefined') {
        $(event.target).toggleClass('open');
    }
    var select = $('#' + select_id.replace(/(:|\.|\[|\])/g, "\\$1"))[0];
    if (select.multiple == true) {
        select.multiple = false;
        select.size = 1;
    } else {
        select.multiple = true;
        select.size = size || 10;
    }
}

function toggleFilterButtons(elButtonsID, elFilter1ID, elFilter2ID)
{
    var elButtons = $('#' + elButtonsID);
    var elFilter1 = $('#' + elFilter1ID);
    var elFilter2 = $('#' + elFilter2ID);

    if (elFilter1.hasClass('collapsed') && elFilter2.hasClass('collapsed')) {
        elButtons.slideUp('slow');
    } else {
        elButtons.slideDown('slow');
    }
}

function ToggleDiv(el_or_id) {
    var el;
    if (typeof el_or_id == 'string') {
        el = $('#' + el_or_id);
    } else {
        el = el_or_id;
    }

    el.toggleClass('collapsed').slideToggle('fast');
}

function ToggleDivAndChangeOpen(toggleElementId, changeOpenElement) {
    ToggleDiv(toggleElementId);
    $(changeOpenElement).toggleClass('open');
}

function UpdateUserPref(uniq_id, user_id, open) {
    $.ajax({
        url: window.saveButtonSettingsUrl || '/users/save_button_settings',
        type: 'POST',
        data: {
            'uniq_id': uniq_id,
            'user': user_id,
            'open': open
        },
        noLoader: true
    });
}
/*
 * ToggleTableRowVisibility('project_index_', 'project', '55', '51');
 */
function ToggleTableRowVisibility(uniq_prefix, entity_name, entity_id, user_id, update_user_pref) {
    var uniq_id = uniq_prefix + entity_name + '-' + entity_id;
    var tr = $('#' + uniq_id);
    if (update_user_pref) {
        UpdateUserPref(uniq_id, user_id, tr.hasClass('open'));
    }
    if (tr.hasClass('open')) {
        HideTableRow(uniq_prefix, entity_name, entity_id, true);
    } else {
        ShowTableRow(uniq_prefix, entity_name, entity_id, false);
    }
}

function HideTableRow(uniq_prefix, entity_name, entity_id, recursive) {
    var tr = $('#' + uniq_prefix + entity_name + '-' + entity_id);
    tr.removeClass('open');
    $('.' + uniq_prefix + 'parent' + entity_name + '_' + entity_id).each(function() {
        $(this).hide();
        if (recursive && this.id) {
            HideTableRow(uniq_prefix, entity_name, this.id.substring((uniq_prefix + entity_name + '-').length), recursive);
        }
    });
}

function ShowTableRow(uniq_prefix, entity_name, entity_id, recursive) {
    var tr = $('#' + uniq_prefix + entity_name + '-' + entity_id);
    tr.addClass('open');
    $('.' + uniq_prefix + 'parent' + entity_name + '_' + entity_id).each(function() {
        $(this).show();
        if (recursive && this.id) {
            ShowTableRow(uniq_prefix, entity_name, this.id.substring((uniq_prefix + entity_name + '-').length), uniq_prefix, recursive);
        }
    });
}

function ToggleTreeVisibility(uniq_prefix, entity_name, entity_id, user_id, update_user_pref, expander_parent) {
    var uniq_id = uniq_prefix + entity_name + '-' + entity_id;
    var ul = $('#' + uniq_id);
    expander_parent = $(expander_parent);
    var isOpen = expander_parent.hasClass('open')
    if (update_user_pref) {
        UpdateUserPref(uniq_id, user_id, isOpen);
    }
    if (isOpen) {
        ul.hide();
        expander_parent.removeClass('open')
    } else {
        ul.show();
        expander_parent.addClass('open');
    }
}

function ToggleTableRowGroupVisibility(el, filter_uniq_id, user_id, update_user_pref) {
    if (update_user_pref) {
        UpdateUserPref(filter_uniq_id, user_id);
    }
    var tr = el.up('tr');
    var n = tr.next();
    tr.toggleClass('open');
    var group_opening = tr.hasClass('open');
    var css_was_visible = "was-visible";
    var css_was_hidden = "was-hidden";
    while (n != undefined && !n.hasClass('group')) {
        if (group_opening) {
            if (n.hasClass(css_was_visible)) {
                Element.show(n);
                n.removeClass(css_was_visible);
            }
            if (n.hasClass(css_was_hidden)) {
                Element.hide(n);
                n.removeClass(css_was_hidden);
            }
        } else {
            n.visible() ? n.addClass(css_was_visible) : n.addClass(css_was_hidden);
            n.hide();
        }
        n = n.next();
    }
}

function apply_query(form_id, url) {
    selectAllOptions("selected_columns");
    $('#' + form_id).attr('action', url).submit();
}

function issuesToggleRowGroup(element, user_id) {
    var tr = $('#' + element);
    var n = tr.next();
    tr.toggleClass('open');
    UpdateUserPref(element, user_id, !tr.hasClass('open'));
    while (n[0] != undefined && !n.hasClass('group')) {
        n.fadeToggle();
        n = n.next();
    }
}

function toggleMyPageModule(expander, element, user, ajaxUpdateUserPref) {
    var group = $(expander).parent('div');
    group.toggleClass('open');
    if (ajaxUpdateUserPref) {
        UpdateUserPref(element, user, !group.hasClass('open'));
    }
    $('#' + element).fadeToggle();
}

function submit_form(form_id, url) {
    var frm = $('#' + form_id);
    frm.attr('action', url);
    frm.submit();
}

function addFileField2(entity_name, entity_id, category) {
    if (fileFieldCount > 14)
        return false
    fileFieldCount++;
    var fields = $('#attachments_fields_' + entity_name + '-' + entity_id);
    var s = $('<span/>');
    s.addClass('nowrap').html(fields.children('span').html());
    category = category == '' ? category : "[" + category + "]";
    input = s.children('input[type=\'file\']').attr('name', "attachments" + category + "[" + fileFieldCount + "][file]");

    input[0].relatedElement = input.next('.fakefile').children('input')[0];
    input[0].onchange = input[0].onmouseout = function() {
        this.relatedElement.value = this.value;
    };
    var desc = s.children('input.description')
    if (desc)
        desc.attr('name', "attachments" + category + "[" + fileFieldCount + "][description]");
    fields.append(document.createElement("br"));
    fields.append(s);
    return false;
}

function removeFileField2(el) {
    el = $(el);
    if (el.closest('div').children('span').length > 1) {
        el.parent().prev('br').remove();
        el.parent().remove();
    }
}

function GoToURL(url, e) {
    var target = e.target || e.srcElement;
    if (target && (target.nodeName == 'INPUT' || target.nodeName == 'A')) {
        return false;
    }
    if (e != null && e != 'undefined') {
        if (!e.ctrlKey && !e.shiftKey && !e.metaKey)
            window.location = url;
    } else {
        window.location = url;
    }
    return true;
}

function ShowAndScrollTo(element_id, offset) {
    ShowAndScrollTo2(element_id, element_id, offset);
}
function ShowAndScrollTo2(show_element_id, scroll_element_id, offset) {
    if (!offset) {
        offset = 0;
    }

    $('#' + show_element_id).show();
    $('html, body').animate({
        scrollTop: $("#" + scroll_element_id).offset().top + offset
    }, 500);
}
// Close menu-more on click out of menu by default on load
$(document).bind('click', function(e) {
    $('.menu-more, .easy-query-tooltip-box').each(function() {
        if ($(this).is(":visible") && !$(this).is(":animated") && e.target.nodeName != "A" && !$(this).hasClass('manual-hide')) {
            ToggleDiv($(this).attr("id"));
        }
    })
})

function easyAutocomplete(name, loadPath, onchange, rootElement) {
    var hiddenInput = $('#' + name);
    var ac = $('#' + name + '_autocomplete').autocomplete({
        source: function(request, response) {
            $.getJSON(loadPath, {
                term: request.term
            }, function(json) {
                response(rootElement ? json[rootElement] : json);
            });
        },
        minLength: 0,
        select: function(event, ui) {
            $(this).val(ui.item.value);
            hiddenInput.val(ui.item.id);
            if (typeof onchange == 'function') {
                onchange();
            }
            hiddenInput.change();
            return false;
        },
        change: function(event, ui) {
            if (!ui.item) {
                $(this).val('');
                hiddenInput.val('');
                if (typeof onchange == 'function') {
                    onchange();
                }
                hiddenInput.change();
            }
        },
        position: {
            collision: "flip"
        },
        autoFocus: true
    }).css('margin-right', 0).click(function() {
        $(this).select();
    });

    if (typeof onchange == 'function') {
        $.data(ac[0], 'ac_onchange_callback', onchange);
    }

    $("<button type='button'>&nbsp;</button>")
            .attr("tabIndex", -1)
            .attr("title", $('#' + name + '_autocomplete').attr("title"))
            .insertAfter(ac)
            .button({
        icons: {
            primary: "ui-icon-triangle-1-s"
        },
        text: false
    })
            .removeClass("ui-corner-all")
            .addClass("ui-corner-right ui-button-icon")
            .css('font-size', '10px')
            .css('margin-left', -1)
            .click(function() {
        if (ac.autocomplete("widget").is(":visible")) {
            ac.autocomplete("close");
            ac.blur();
            return;
        }
        $(this).blur();
        ac.focus().val('');
        ac.trigger('keydown');
        ac.autocomplete("search", "");
    });
}

function easyMultiselectTag(id, name, possibleValues, selectedValues) {
    var entities,
        entityArray = $('#' + id + '_entity_array'),
        ac = $('#' + id + '_autocomplete');

    entities = $.map(possibleValues, function (val) {
        if (selectedValues && (selectedValues.indexOf(val.id) > -1) || (selectedValues.indexOf(val.id.toString()) > -1)) {
            return {
                id: val.id,
                name: val.value
            };
        }
    });

    entityArray.entityArray({
        inputNames: name,
        entities: entities
    });

    ac.autocomplete({
        source: function(request, response) {
            var matcher = new RegExp( $.ui.autocomplete.escapeRegex(request.term), "i" );
            response($.map(possibleValues, function (val) {
                if (!request.term || matcher.test(val.value)) {
                    return val;
                }
            }));
        },
        minLength: 0,
        select: function(event, ui) {
            entityArray.entityArray('add', {
                id: ui.item.id,
                name: ui.item.value
            });
            return false;
        },
        change: function(event, ui) {
            if (!ui.item) {
                $(this).val('');
            }
        },
        position: {
            collision: "flip"
        },
        autoFocus: true
    });
    $("<button type='button'>&nbsp;</button>")
        .attr("tabIndex", -1)
        .insertAfter(ac)
        .button({
            icons: {
                primary: "ui-icon-triangle-1-s"
            },
            text: false
        })
        .removeClass("ui-corner-all")
        .addClass("ui-corner-right ui-button-icon")
        .css('font-size', '10px')
        .css('margin-left', -1)
        .click(function() {
            if (ac.autocomplete("widget").is(":visible")) {
                ac.autocomplete("close");
                ac.blur();
                return;
            }
            $(this).blur();
            ac.focus().val('');
            ac.trigger('keydown');
            ac.autocomplete("search", "");
        });
}

function Right(str, n) {
    if (n <= 0) {
        return "";
    } else if (n > String(str).length) {
        return str;
    } else {
        var iLen = String(str).length;
        return String(str).substring(iLen, iLen - n);
    }
}

function displayTabsButtons2(css_selector) {
    var lis;
    var tabsWidth = 0;
    var i;
    $(css_selector).each(function() {
        lis = $(this).find('ul').children('li');
        lis.each(function(index, li) {
            if ($(li).is(":visible")) {
                tabsWidth += $(li).width() + 6;
            }
        })
        if ((tabsWidth < $(this).width() - 60) && (lis.first().is(":visible"))) {
            $(this).find('div.tabs-buttons, td.tabs-button').hide();
        } else {
            $(this).find('div.tabs-buttons, td.tabs-button').show();
        }
    });
}

function switchElements(from_el, to_el) {
    $(from_el).hide();
    $(to_el).show();
}

function setEasyAutoCompleteValue(select_element_id, value_id, value_name) {
    var ac = $('#' + select_element_id + '_autocomplete');
    if (ac) {
        ac.val(value_name);
        $('#' + select_element_id).attr('value', value_id);
        var onchange = $.data(ac[0], 'ac_onchange_callback');
        if (typeof onchange == 'function')
            onchange();
    } else {
        var sel = $('#' + select_element_id);
        sel.attr('value', value_id);
        sel.change();
    }
}

function isIE() {
    return getInternetExplorerVersion() != -1
}

// From http://msdn.microsoft.com/en-us/library/ms537509%28v=vs.85%29.aspx
function getInternetExplorerVersion() {
    // Returns the version of Internet Explorer or a -1
    // (indicating the use of another browser).
    var rv = -1; // Return value assumes failure.
    if (navigator.appName == 'Microsoft Internet Explorer')
    {
        var ua = navigator.userAgent;
        var re = new RegExp("MSIE ([0-9]{1,}[\.0-9]{0,})");
        if (re.exec(ua) != null)
            rv = parseFloat(RegExp.$1);
    }
    return rv;
}

var key_count_global = null;

function focusWiki(id) {
// NOT WORKING CORRECTLY IN FF

// setTimeout(function () {
//     if (window.CKEDITOR && CKEDITOR.instances && CKEDITOR.instances[id]) {
//         var editor = CKEDITOR.instances[id];
//         if (editor.getData() == '') editor.setData(''); //ugly hack, solves extra line issue in FF
//         editor.focus();
//     } else if ($(id)) {
//         $(id).focus();
//     }
// }, 700);
}

function toggleCheckbox(id) {
    el = $('#' + id);
    if (el) {
        el.attr("checked", !el.is(":checked"));
    }
}

function updateResourceAvailability(date, hour, uuid, available, desc_msg) {
    $('#date-' + uuid).val(date);
    $('#hour-' + uuid).val(hour ? hour : '');
    $('#available-' + uuid).val(available ? '1' : '');
    if (!available) {
        $('#description-' + uuid).val(prompt(desc_msg));
    }
    var uf = $('#resource-availibility-update-form-' + uuid)
    $.post(uf.attr('action'), uf.serialize(), function() {
        $('#module_' + uuid).load('/my/update_my_page_module_view', $('#resource-availability-form-' + uuid).serialize());
    });
}

function setInfiniteScrollDefaults() {
    $.extend($.infinitescroll.defaults, {
        behavior: 'easy'
    });
    $.infinitescroll.prototype._nearbottom_easy = function() {
        var opts = this.options;
        var pixelsFromWindowBottomToBottom = 0 + $(document).height() - (opts.binder.scrollTop()) - $(window).height();
        var cnt = $(opts.contentSelector);
        var navToBottom = $(document).height() - cnt.position().top - cnt.height();

        // var lastTr = $('table.list:first > tbody > tr:last');
        // if (lastTr.hasClass('summary')) {
        //     lastTr.remove();
        // }

        return pixelsFromWindowBottomToBottom < navToBottom + opts.bufferPx;
    };
    $.extend($.infinitescroll.defaults.loading, {
        selector: '#content',
        msgText: '',
        finishedMsg: ''
    });
}

function isInputTypeSupported(typeName) {
    // Create element
    var input = document.createElement("input");
    // attempt to set the specified type
    input.setAttribute("type", typeName);
    // If the "type" property equals "text"
    // then that input type is not supported
    // by the browser
    var val = (input.type !== "text");
    // Delete "input" variable to
    // clear up its resources
    delete input;
    // Return the detected value
    return val;
}
function initProjectAdminSearch(url) {
    $(function() {
        var timeoutId;
        $('#easy_query_q').keyup(function(e) {
            if (timeoutId)
                clearTimeout(timeoutId);
            timeoutId = setTimeout(projectSearch, 300);
        });

        var projects = $('#projects');
        function projectSearch() {
            var q = $('#easy_query_q').val();
            if (!q || q.length < 3)
                return false;
            $.post(url, $('#query_form, #easy_query_q').serialize(), function(resp) {
                window.resp = resp;
                projects.html(resp);
            });
        }
    });
}
;
// ---------------------------------------------------------------------------------------------------
// context_menu.js patch
//
if (window.contextMenuInit && window.contextMenuRightClick) {

    window.contextMenuShow = function(event) {
        var mouse_x = event.pageX;
        var mouse_y = event.pageY;
        var render_x = mouse_x;
        var render_y = mouse_y;
        var dims;
        var menu_width;
        var menu_height;
        var window_width;
        var window_height;
        var max_width;
        var max_height;

        $('#context-menu').css('left', (render_x + 'px'));
        $('#context-menu').css('top', (render_y + 'px'));
        $('#context-menu').html('');

        $.ajax({
            url: $.data($(event.target).closest(".context-menu-container")[0], 'contextMenuUrl'),
            data: $(event.target).closest('form').first().serialize(),
            success: function(data, textStatus, jqXHR) {
                $('#context-menu').html(data);
                menu_width = $('#context-menu').width();
                menu_height = $('#context-menu').height();
                max_width = mouse_x + 2 * menu_width;
                max_height = mouse_y + menu_height;

                var ws = window_size();
                window_width = ws.width;
                window_height = ws.height;

                /* display the menu above and/or to the left of the click if needed */
                if (max_width > window_width) {
                    render_x -= menu_width;
                    $('#context-menu').addClass('reverse-x');
                } else {
                    $('#context-menu').removeClass('reverse-x');
                }
                if (max_height > window_height) {
                    render_y -= menu_height;
                    $('#context-menu').addClass('reverse-y');
                } else {
                    $('#context-menu').removeClass('reverse-y');
                }
                if (render_x <= 0)
                    render_x = 1;
                if (render_y <= 0)
                    render_y = 1;
                $('#context-menu').css('left', (render_x + 'px'));
                $('#context-menu').css('top', (render_y + 'px'));
                $('#context-menu').show();

                //if (window.parseStylesheets) { window.parseStylesheets(); } // IE

            }
        });
    };
    window.contextMenuInit = function(url, element) {
        context_menu_parent = $(element);
        if (context_menu_parent[0]) {
            has_el_context_menu = (url == '') ? false : true;
            context_menu_parent.each(function(i) {
                $.data(this, 'contextMenuUrl', url);
                $(this).addClass("context-menu-container");
            });
            contextMenuCreate();
            //contextMenuUnselectAll();   // tohle rozbiji modalni okna

            if (!contextMenuObserving) {
                $(document).click(contextMenuClick);
                if (has_el_context_menu) {
                    $(document).contextmenu(contextMenuRightClick);
                }
                contextMenuObserving = true;
            }
        }
    }

    window.contextMenuClick = function(event) {
        var target = $(event.target);
        var lastSelected;

        if (target.is('a') && target.hasClass('submenu')) {
            event.preventDefault();
            return;
        }
        contextMenuHide();
        if (target.is('a') || target.is('img') || target.hasClass('expander')) {
            return;
        }
        if (event.which == 1 /*TODO || (navigator.appVersion.match(/\bMSIE\b/))*/) {
            var tr = target.parents('tr').first();
            if (tr.length && tr.hasClass('hascontextmenu')) {
                // a row was clicked, check if the click was on checkbox
                if (target.is('input')) {
                    // a checkbox may be clicked
                    if (target.attr('checked')) {
                        tr.addClass('context-menu-selection');
                    } else {
                        tr.removeClass('context-menu-selection');
                    }
                } else {
                    if (event.ctrlKey || event.metaKey) {
                        contextMenuToggleSelection(tr);
                    } else if (event.shiftKey) {
                        lastSelected = contextMenuLastSelected();
                        if (lastSelected.length) {
                            var toggling = false;
                            $('.hascontextmenu').each(function() {
                                if (toggling || $(this).is(tr)) {
                                    contextMenuAddSelection($(this));
                                }
                                if ($(this).is(tr) || $(this).is(lastSelected)) {
                                    toggling = !toggling;
                                }
                            });
                        } else {
                            contextMenuAddSelection(tr);
                        }
                    } else {
                        contextMenuUnselectAll();
                        contextMenuAddSelection(tr);
                    }
                    contextMenuSetLastSelected(tr);
                }
            } else {
                // click is outside the rows
                if (!target.is('a') || !(target.hasClass('disabled') || target.hasClass('submenu')) || target.is('input')) {
                    if (!target.closest(".ui-dialog-content").is('*')) {
                        contextMenuUnselectAll();
                    }
                }
            }
        }
    }

    window.contextMenuCheckSelectionBox = function(tr, checked) {
        input = tr.find('input[type="checkbox"], input[type="radio"]').attr('checked', checked).change();
    }

    window.contextMenuRightClick = function(event) {
        if (!$(event.target).closest(".context-menu-container")[0]) {
            return;
        }
        var ctx_url = $.data($(event.target).closest(".context-menu-container")[0], 'contextMenuUrl');
        if (ctx_url == '')
            return;
        var target = $(event.target);
        if (target.is('a')) {
            return;
        }
        var tr = target.parents('tr').first();
        if (!tr.hasClass('hascontextmenu')) {
            return;
        }
        event.preventDefault();
        if (!contextMenuIsSelected(tr)) {
            contextMenuUnselectAll();
            contextMenuAddSelection(tr);
            contextMenuSetLastSelected(tr);
        }
        contextMenuShow(event);
    }

}
//
// --------------------------------------

function showAjaxFullscreen(url, callback) {
    createModalSelectorWindow('99%');
    $('#modal-dialog-loader-wrapper').dialog('option', 'height', window.innerHeight);
    $('#modal-dialog-loader-wrapper').dialog('option', 'position', 'top').load(url, {}, callback);
}
function easyAttendanceToggleTimeAndRange(display) {
    r = $(".easy-attendance-time-select");
    t = $("#easy-attendance-range-select");
    if (display) {
        r.hide();
        t.show();
        t.find("input").attr("disabled", false);
        if (t.find("input:checked").length == 0) {
            t.find("input").first().attr("checked", true);
        }
    } else {
        r.show();
        t.hide();
        t.find("input").attr("disabled", true);
    }
}

if (!Array.prototype.indexOf) {
    Array.prototype.indexOf = function(elt /*, from*/) {
        var len = this.length >>> 0;
        var from = Number(arguments[1]) || 0;
        from = (from < 0)
                ? Math.ceil(from)
                : Math.floor(from);
        if (from < 0)
            from += len;

        for (; from < len; from++) {
            if (from in this &&
                    this[from] === elt)
                return from;
        }
        return -1;
    };
}

$(document).ready(function() {
    $(".form-disabled-on-ajax").bind("ajaxSend", function(event, xhr, settings) {
        $(".form-disabled-on-ajax").attr('data-submitted', true);
    })
    $(".form-disabled-on-ajax").bind("ajaxStop", function(event, xhr, settings) {
        $(".form-disabled-on-ajax").removeAttr('data-submitted');
    })
    // Customize file inputs
    initFileUploads();
    // init triggers
    if (window.contextMenuRightClick) {
        $('.btn_contextmenu_trigger').live('click', contextMenuRightClick);
    }
    // automatic manual expander :)
    $(function() {
        $('div.module-toggle-button.manual').click(function() {
            $(this).next('div').toggle();
            $('div.group:first', this).toggleClass('open');
        });
    });
    if (getRegisterPanelHandlerTargets().length > 0) {
        $("*[data-handler=true]").each(function(i, handler) {
            $(handler).addClass('easy-panel-handler-container');
            var handle = $("<span/>").attr({"class":'easy-panel-handler icon-cross-move', "data-entity-type": $(handler).data().entityType.toLowerCase()});
            $.each(getRegisterPanelHandlerTargets(), function(index, item) {
                if (item.handlerAllowed($(handler))){
                    handle.attr(item.dataAttributes($(handler)));
                    $(handler).append(handle);
                }
            })
        })
    }
    var available_types = $.map($(".easy-panel-handler-container .easy-panel-handler"), function(n) {return  $(n).data().entityType});

    if (available_types[0]) {
       $.each($.unique(available_types), function(index, type){
           $(".easy-panel-handler-container .easy-panel-handler[data-entity-type="+type+"]").draggable({
               cursorAt: {
                   top: 1,
                   left: 1
               },
               connectToSortable: $.map(getRegisterPanelHandlerTargets(), function(item,i) {if (item.allowedEntity(type)) return item.connectToSortable()}).join(','),
               revert: "invalid",
               zIndex: 101,
               scroll: false,
               helper: function (event) {
                   return $('<li class="movable-list-item ui-state-default" style="width: auto; height: auto; min-width: 100px;">' + $(this).parent().text() + '</li>');
               },
               start: function(event, ui) {
                   $.each(getRegisterPanelHandlerTargets(), function(index, item) {
                       if (item.allowedEntity(type)) {
                           $("#"+item.containerName+" .clicker-panel > span").bind('mouseover', function(e) {
                               $(e.target).click();
                           })
                       }
                   })
               },
               stop: function(event, ui) {
                   $.each(getRegisterPanelHandlerTargets(), function(index, item) {
                       $("#"+item.containerName+" .clicker-panel > span").unbind('mouseover');
                   })
               }
           });
       });
    }


  $(".list.reorder tbody").sortable({
      handle: ".easy-sortable-list-handle",
      helper: function(event, currentItem) {
          var t = $("<tr/>").css({border:'none'});
          t.append($("<td/>").html("<span class=\"icon-reorder\"></span>"));
          t.append($("<td/>").attr({"class":"name", colspan: currentItem.find("td").length - 1}).text(currentItem.find("td.name").text()))

          return t.attr({"class":"easy-sortable-helper"})
      },
      placeholder: {
          element: function(currentItem) {
              var t = $("<tr/>")
              t.append($("<td/>")).append($("<td/>").attr({"class":"name", colspan: currentItem.find("td").length - 1}).html("&nbsp;"));

              return t.attr({"class":"easy-sortable-placeholder"})
          },
          update: function(container, p) {
              return;
          }
      },
      update: function(event, ui){
        var handler = ui.item.find(".easy-sortable-list-handle");
        var params = {data:{format:'json'}};
        params.data[handler.data().name] = {reorder_to_position: ui.item.index() + 1}

        $.ajax(handler.data().url, {data : params.data, type : 'PUT'})
      }
    });

    $('#ajax-indicator').unbind('ajaxSend').bind('ajaxSend', function (event, xhr, settings) {
        if (!settings.noLoader && $('.ajax-loading').length === 0 && settings.contentType != 'application/octet-stream') {
            $('#ajax-indicator').show();
        }
    });

    if (window.enableWarnLeavingUnsaved) {
        var warnLeavingUnsavedMessage;
        $('textarea').closest('form').data('changed', 'changed');
        $('form').live('submit', function(){
            $('textarea').closest('form').removeData('changed');
        });

        function beforeUnload() {
            var warn = false;
            for ( var name in CKEDITOR.instances ) {
                var editor = CKEDITOR.instances[name];

                if ( $(editor.element.$.form).data() && $(editor.element.$.form).data().changed && CKEDITOR.instances[name].checkDirty() )
                    warn = true;
            }

            if (warn) {return window.I18n.textWarnLeavingUnsaved;}
        };

        if ( window.addEventListener )
            window.addEventListener( "beforenload", beforeUnload, false );
        else
            window.attachEvent( "onbeforeunload", beforeUnload );
    }


});

function initFileUploads() {
    var fakeFileUpload = document.createElement('div');
    fakeFileUpload.className = 'fakefile';
    fakeFileUpload.appendChild(document.createElement('input'));
    var button = document.createElement('span');
    button.className = 'fakefileButton button-2';
    fakeFileUpload.appendChild(button);
    var x = $("input:file.file_selector");
    for (var i = 0; i < x.length; i++) {
        if (x[i].type != 'file')
            continue;
        //if (x[i].parentNode.className != 'fileinputs') continue;
        $(x[i]).addClass('file hidden');
        var clone = fakeFileUpload.cloneNode(true);
        $(clone).find('.fakefileButton').html($(x[i]).attr('title'));
        x[i].parentNode.appendChild(clone);
        x[i].relatedElement = clone.getElementsByTagName('input')[0];
    }
}

EPExtensions = {
    setup: function() {
        $('.set_attachment_reminder').each(function(index) {
            EPExtensions.initReminder(this);
        });
        $('.checks_other_element').click(function() {
            EPExtensions.checkElement($('#' + $(this).data('checks')));
            $(this).focus();
        });
        //---- Authentication -----
        $('.selectable-authentication').click(function(e){
            $('.selectable-authentication').removeClass('selected');
            var $form = $(this).closest('form');
            if( $form.length == 0 ) return;
            var name = $(this).closest('.authentications').data('name');
            var id = (name).replace(/\[/,'_').replace(/\]/,'');
            var $elem = $form.find('#'+id);
            var uid =  $(this).find('.uid').data('uid');
            if( $elem.length > 0 ) {
                $elem.attr('value', uid);
            } else {
                var $elem = $('<input></input>',{'type':'hidden', 'id': id, 'name': name,'value': uid});
                $form.prepend($elem);
            }
            $(this).addClass('selected');
        });
    },
    initReminder: function(element) {
        //var className = 'form_with_attachment_reminder';
        var $form = $(element).parents('form'); //wish it is a single element, but if don't, should not be problem
        //$form.removeClass(className).addClass(className);
        $form.submit(function(event) {
            var textareaId = $(element).attr('id');
            var isCK = $(element).data('ck');
            var value = EPExtensions.getDescriptionValue(textareaId, isCK);
            var confirm_message = $(element).data('reminder_confirm');
            var words = $(element).data('reminder_words');
            var regex = RegExp(words);
            if (value.match(regex)) {
                if (EPExtensions.hasFileAttached(this)) {
                    return true;
                }
                if (!confirm(confirm_message)) {
                    $form.removeAttr('data-submitted');
                    return false;
                }
            }
        });
    },
    getDescriptionValue: function(elementId, isCK) {
        if (isCK) {
            var instance = CKEDITOR.instances[elementId]
            if (instance) {
                return instance.getData();
            } else {
                return '';
            }
        } else {
            return $('#' + elementId).val();
        }
    },
    hasFileAttached: function(formElement) {
        var hasFile = false
        $(formElement).find('input[name*="attachments"]').filter(function() {
            return $(this).attr('name').match(/attachments\[\d+\]\[token\]/);
        }).each(function(index) {
            if ($(this).val() != "") {
                hasFile = true;
                return true;
            }
        });
        $(formElement).find('input[type="file"],input[type="dropbox-minechooser"]').each(function(index) {
            if ($(this).val() != "") {
                hasFile = true;
                return true;
            }
        });

        return hasFile;
    },
    checkElement: function(el) {
        $(el).prop("checked", true);
    }
};
$(EPExtensions.setup);

function toggleSidebar() {
    $("#sidebar").closest(".grid_3").toggle().prev().toggleClass("grid_9 grid_12");
}

function initShorRangeTimeSelectEasyAttendance() {
    $(".easy-attendance-range-half-day-radio input").change(function(event) {
        showRangeTimeSelectEasyAttendance(event)
    });
    $(".easy-attendance-range-half-day-radio input:checked").change();
}
function showRangeTimeSelectEasyAttendance(event) {
    $(".easy-attendance-time-dropper").remove();

    var radio = $(event.target);
    radio.closest("#easy-attendance-range-select").css({"margin-bottom": "50px"});
    span = $("<span/>").attr({"class": "easy-attendance-time-dropper nowrap", "title": radio.data().infoText});
    span.append($("<label/>").attr({"for": "range_start_time_time"}).text(radio.data().labelFrom));

    var i = $("<input/>").attr({"type": "time", "size": "3", "name": "range_start_time[time]", "id": "range_start_time_time", "value": radio.data().startTime});
    i.on("input", function(e) {
        info = i.next("label.easy-attendance-time-to-info");
        time = moment(i.val(), "HH:mm");
        info.text(radio.data().labelTo + " " + time.add("hours", radio.data().halfDayHours).format("HH:mm"));
    })

    span.append(i);
    span.append($("<label/>").attr({"class": "easy-attendance-time-to-info"}));
    span.insertAfter(radio);
}
(function($) {
    "use strict";
    $.fn.easySlidingPanel = function(options) {

        var defaults = {
            position: 'left'
        }
        var opts = $.extend(true, {}, defaults, options);

        var _self = $(this);
        var clicker_panel = _self.find(".clicker-panel");
        var expaded = false;
        var expanded_panel_width = "-357px";
        var top_position_onload;

        eval("move" + opts.position.charAt(0).toUpperCase() + opts.position.slice(1))();

        //_self.css(opts.position, expanded_panel_width);
        _self.show();
        _self.draggable({
            handle: ".expander-panel-content, .clicker-panel",
            revert: function(socketObj) {
                if (socketObj === false)
                {
                    eval("move" + opts.position.charAt(0).toUpperCase() + opts.position.slice(1))();
                    return true;
                }
                else
                {
                    return false;
                }
            },
            //snap: 'section.easy-slider-sections',
            scroll: false,
            snapToleranceType: 100,
            start: function(event, ui) {
                _self.removeAttr("style");
                var panels = {"easy_panel_left": "left", "easy_panel_right": "right", "easy_panel_bottom": "bottom"};
                for (var e in panels) {
                    $("#" + e).remove();
                    if (!$("#" + e)[0]) {
                        var zone = $("<section/>").attr({"id": e, "class": "easy-slider-sections", "data-zone": panels[e]});
                        $("body").append(zone);
                        var zone = $("#" + e);
                        zone.droppable({
                            tolerance: "pointer",
                            accept: 'div.easy-sliding-panel-container',
                            activeClass: "ui-state-hover easy-slider-target-zone-active",
                            hoverClass: "ui-state-active easy-slider-target-zone-hover",
                            drop: function(event, ui) {
                                ui.draggable.preventDefault;
                                $.post(_self.data().saveLocationUrl, {'panel_name': _self.data().panelName, 'panel_zone': $(event.target).data().zone});
                                top_position_onload = null;
                                eval("move" + $(event.target).data().zone.charAt(0).toUpperCase() + $(event.target).data().zone.slice(1))();
                                _self.closeExpander();
                            }
                        });
                    }

                }
                ;
            }
        });

        function moveRight() {
            opts.position = 'right';
            var top = 100;
            _self.removeAttr("style");
            _self.css(opts.position, expanded_panel_width);

            _self.css("top", top.toString() + "px");
            _self.find(".clicker-panel").removeAttr("style").css({
                "left": "-110px",
                "width": "190px",
                "top": "79px",
                "-filter": "progid:DXImageTransform.Microsoft.BasicImage(rotation=4)",
                "transform": "rotate(-90deg)",
                "-moz-transform": "rotate(-90deg)",
                "-webkit-transform": "rotate(-90deg)"
            }).addClass('right-side').removeClass('bottom-side').removeClass('left-side');

            reorderPanels("right");
        }
        function moveLeft() {
            opts.position = 'left';
            var top = 100;
            _self.removeAttr("style");
            _self.css("top", top.toString() + "px");
            _self.css(opts.position, expanded_panel_width);


            _self.find(".clicker-panel").removeAttr("style").css({
                "right": "-110px",
                "width": "190px",
                "top": "79px",
                "-filter": "progid:DXImageTransform.Microsoft.BasicImage(rotation=4)",
                "transform": "rotate(90deg)",
                "-moz-transform": "rotate(90deg)",
                "-webkit-transform": "rotate(90deg)"

            }).addClass('left-side').removeClass('right-side').removeClass('bottom-side');

            reorderPanels("left");
        }

        function moveBottom() {
            opts.position = 'bottom';
            _self.removeAttr("style");
            // "left":"50%, margin-left": "-"+ (_self.width() / 2).toString()+"px"
            _self.css({"bottom": "-" + (_self.height() - 27).toString() + "px", "left": (((($(window).width() - _self.width()) / 2) * 100) / $(window).width()).toString() + "%"});
            _self.find(".clicker-panel").removeAttr("style").css({
                "left": "50%",
                "width": "200px",
                "top": "-25px",
                "text-align": "center",
                "margin-left": "-100px"
            }).addClass('bottom-side').removeClass('right-side').removeClass('left-side');
        }

        function reorderPanels(panel) {
            var items = $(".clicker-panel." + panel + "-side").closest('.easy-sliding-panel-container')
            items.each(function(index, item) {
                var prev_item = items[index - 1];
                if (prev_item) {
                    $(item).css("top", (parseInt($(prev_item).css("top")) + 15 + ($(prev_item).height() / 2)).toString() + "px");
                }


            });
        }

        this.openExpander = function() {
            if (expaded)
                return;
            var openExpanderOpts = {};
            if (opts.position == 'bottom') {
                openExpanderOpts[opts.position] = 27;
            } else {
                openExpanderOpts[opts.position] = "0";
            }
            _self.animate(openExpanderOpts, "slow", null, function() {
                expaded = true;
                if (typeof(opts.afterOpen) == 'function') {
                    opts.afterOpen()
                }
            });
            _self.addClass('open')
        }

        this.closeExpander = function() {
            if (!expaded)
                return;
            var closeExpanderOpts = {};
            if (opts.position == 'bottom') {
                closeExpanderOpts[opts.position] = "-" + (_self.height() - 27).toString() + "px";
            } else {
                closeExpanderOpts[opts.position] = expanded_panel_width;
            }
            _self.animate(closeExpanderOpts, "slow", null, function() {
                expaded = false;
                if (typeof(opts.afterClose) == 'function') {
                    opts.afterClose()
                }
            });
            _self.removeClass('open');
        }

        this.toggleExpander = function() {
            if (expaded) {
                _self.closeExpander();
            } else {
                _self.openExpander();
            }
        }

        this.initialize = function() {
            _self = this;
            $(document).bind('click', function(e) {
                if (_self.hasClass('open') && e.target.nodeName != "A" && !$(e.target).closest('.easy-sliding-panel-container')[0]) {
                    _self.closeExpander();
                }
            })
            return this;
        }

        clicker_panel.find('span').click(function() {
            _self.toggleExpander()
        });



        return this.initialize();
    }
}(jQuery));
function createEasyDropZone(target, label) {
    target = $(target).css('position', 'relative');
    return $("<div/>").addClass("easy-target-dropzone").html(label).appendTo(target);
}
(function($) {
    "use strict";
    var easy_register_panel_handler_targets = [];
    window.registerPanelHandlerTarget = function(target) {
        easy_register_panel_handler_targets.push(target);
    }
    window.getRegisterPanelHandlerTargets = function() {
        return easy_register_panel_handler_targets;
    }
}(jQuery));

function redirectToPageLayout() {
    var page_layout_button = $('#easy-page-layout-service-box-bottom').find('a');
    if (page_layout_button[0]) {
        window.location = page_layout_button.attr('href');
    }
}

function collapseUnnecessaryJournals() {
    var journals_to_hide = $(".journal span.expander.issue-journal-details-toggler").closest('.journal').toArray();
    if ($(journals_to_hide).last()[0] == $(".journal.has-details:last-child").last()[0]) {
      journals_to_hide.pop(); // all except last
    }
    $(journals_to_hide).each(function(index, i) {
      toggleJournalDetails($(i));
    })
    $(".journal span.expander.issue-journal-details-toggler").click(function(event) {
      expander = $(event.target);
      toggleJournalDetails(expander.closest(".journal"));

    })
}
function toggleJournalDetails(journal) {
  journal.find(".avatar-container img").toggleClass('smallest-avatar')
  journal.find(".journal-details-container").find('ul').toggle();
  journal.find(".expander").parent().toggleClass('open');
}
