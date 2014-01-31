/*globals jQuery */
/*jslint browser: true, devel: true*/
;(function ($, window, document, undefined) {
    "use strict";

    var pluginName = "agileboard",
        defaults = {
            newSprintUrl: null
        };

    function Plugin (element, options) {
        this.element = element;
        this.options = $.extend({}, defaults, options);
        this._defaults = defaults;
        this._name = pluginName;
        this.init();
    }

    Plugin.prototype = {

        init: function () {
            this.sidebar = $(".agile-board-sidebar", this.element).accordion({
                heightStyle: "content",
                collapsible: true
            });
            this.body = $(".agile-board-body", this.element);
            this.loadSprints();
            if (this.options.editable) {
                this.initProjectBacklog();
                this.initProjectTeam();
            }
        },

        initProjectBacklog: function () {
            this.projectBacklog = $(".project-backlog", this.element)
            this.initAgileListItems($("li", this.projectBacklog));
            $(".agile-list", this.projectBacklog).droppable({
                activeClass: 'droppable-active',
                hoverClass: 'droppable-hover',
                accept: '.agile-issue-item',
                tolerance: 'pointer',
                drop: function (event, ui) {
                    ui.draggable.appendTo(this);
                    $.post('easy_sprints/unassign_issue', {
                        issue_id: ui.draggable.data('id')
                    });
                }
            });
        },

        initAgileListItems: function (el) {
            el.draggable({
                helper: "clone",
                cursorAt: {left: 10, top: 10}
            }).droppable({
                activeClass: 'droppable-active',
                hoverClass: 'droppable-hover',
                accept: '.member',
                tolerance: 'pointer',
                drop: function (event, ui) {
                    $(".avatar-container", this).remove();
                    var ac = $(".avatar-container", ui.draggable).clone().prependTo($(this));
                    $("img", ac).attr("width", 50).attr("height", 50);
                    $.ajax({
                        url: "/issues/" + $(this).data("id") + ".json",
                        type: "PUT",
                        data: {issue: {assigned_to_id: ui.draggable.data("id")}}
                    });
                }
            });
        },

        initProjectTeam: function () {
            this.projectTeam = $(".project-team", this.element);
            $("div.member", this.projectTeam).draggable({
                helper: function () {
                    return $(".avatar-container", this).clone();
                },
                cursorAt: {left: 10, top: 10}
            })
        },

        newSprint: function () {
            var self = this;
            if (this.newSprintForm) {
                this.newSprintForm.remove();
            }
            $.get(this.options.newSprintUrl, function(resp) {
                self.newSprintForm = $(resp).prependTo(self.body).submit(function () {
                    self.createSprint();
                    return false;
                });
            });
        },

        createSprint: function () {
            var self = this;
            $.ajax({
                url: this.options.sprintsUrl + ".json",
                type: "POST",
                data: this.newSprintForm.serialize(),
                complete: function(resp) {
                    if (resp.status === 422) {
                        self.validationErrors($.parseJSON(resp.responseText).errors);
                    } else {
                        self.loadSprints();
                    }
                }
            });
        },

        validationErrors: function (errors) {
            var err, ul;
            $("#errorExplanation").remove();
            err = $("<div/>")
                .prependTo(this.body)
                .attr("id", "errorExplanation");
            ul = $("<ul/>").appendTo(err);
            if (errors) {
                $("<li/>").appendTo(ul).html(errors.join('<br/>'));
            }
        },

        loadSprints: function () {
            var self = this;
            this.sprints = [];
            this.body.load(this.options.sprintsUrl, function () {
                $(".easy-sprint", this.element).each(function () {
                    self.sprints.push(new Sprint(self, $(this)));
                });
                if (self.options.editable) {
                    self.newSprint();
                }
            });
        },

    };

    function Sprint(plugin, element) {
        this.plugin = plugin;
        this.element = element;
        this.init();
    }

    Sprint.prototype = {
        init: function () {
            var self = this;
            if (this.plugin.options.editable) {
                $(".agile-list", this.element).droppable({
                    activeClass: 'droppable-active',
                    hoverClass: 'droppable-hover',
                    accept: '.agile-issue-item',
                    tolerance: 'pointer',
                    drop: function (event, ui) {
                        ui.draggable.appendTo(this);
                        $.post('easy_sprints/' + self.element.data('id') + '/assign_issue', {
                            issue_id: ui.draggable.data('id'),
                            relation_type: $(this).data('relation-type')
                        });
                    }
                });
                this.plugin.initAgileListItems($("li", this.element));
            }
        }
    };

    $.fn[pluginName] = function (options, methodAttrs) {
        return this.each(function () {
            var instance = $.data(this, "plugin_" + pluginName);
            if (!instance) {
                $.data(this, "plugin_" + pluginName, new Plugin($(this), options));
            } else if (typeof options === "string") {
                instance[options].call(instance, methodAttrs);
            }
        });
    };

})(jQuery, window, document);
