(function ($) {
    // defaults
    $.extend($.fn.editable.defaults, {
        send: 'always',
        toggle: 'manual',
        ajaxOptions: {type: 'PUT'},
        emptytext: '-',
        title: '',
        params: function (data) {
            var params = {};
            params[data.name] = data.value;
            return params;
        },
        error: function (xhr) {
            var json = $.parseJSON(xhr.responseText);
            if (json && json.errors) {
                return json.errors.join("\n");
            }
        }
    });

    // DateUI
    $.fn.editabletypes.dateui.prototype.value2html = function(value, element) {
        var text;
        if (value) {
            text = moment(value).format(momentjsFormat);
        } else {
            text = '';
        }
        $.fn.editabletypes.dateui.superclass.value2html(text, element);
    };
    $.fn.editableform.Constructor.prototype.showLoading = function () {};

    // Hours
    var Hours = function (options) {
        this.init('hours', options, Hours.defaults);
    };
    $.fn.editableutils.inherit(Hours, $.fn.editabletypes.text);
    $.extend(Hours.prototype, {
        input2value: function () {
            var val = parseFloat(this.$input.val());
            if (isNaN(val)) {
                return null;
            }
            return val;
        },
        value2html: function (value, element) {
            if (!value) {
                $(element).text('');
            } else {
                var fixed = value.toFixed(2).split('.');
                $('<span/>').addClass('hours hours-int').text(fixed[0]).appendTo($(element).empty());
                $('<span/>').addClass('hours hours-dec').text('.' + fixed[1]).appendTo($(element));
            }
        }
    });
    Hours.defaults = $.extend({}, $.fn.editabletypes.text.defaults, {});
    $.fn.editabletypes.hours = Hours;

    // initialization
    $(function () {
        $.fn.editabletypes.dateui.defaults.datepicker = datepickerOptions;
        window.initInlineEditForContainer = function (container) {
            var me = $('.multieditable', container)
                .editable($.extend($(container).data(), {title: ' '}))
                .attr('title', I18n.titleInlineEditable);
            $('<span/>')
                .addClass('icon-edit')
                .attr('title', I18n.titleInlineEditable)
                .insertAfter(me)
                .click(function () {
                    $(this).prev().editable('toggle');
                    return false;
                });
            $(container).addClass('multieditable-initialized');
        }

        $('.multieditable-container').each(function () {
            initInlineEditForContainer(this);
        });
    });
}(jQuery));
