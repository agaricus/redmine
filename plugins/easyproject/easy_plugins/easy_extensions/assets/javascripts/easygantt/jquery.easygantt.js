(function ($) {
    var gantt,
    settings = {
        relativeUrlRoot: '/',
        dayWidth: 24,
        rowHeight: 22,
        loadUrl: 'gantt.json',
        allowParentIssueMovement: true,
        saveIssuesUrl: 'gantt/update_issues',
        validateIssueUrl: 'gantt/validate_issue',
        visibleRelations: ['follows', 'blocks'],
        dateFormat: 'YYYY-MM-DD',
        humanDateFormat: 'D. M. YYYY',
        holidays: [],
        saveCallback: function (response) {
            $('#content div.flash').remove();
            $('<div/>').addClass('flash').addClass(response.type).append($('<span/>').html(response.html)).prependTo($('#content'));
        },
        issueWormCallback: null,
        todayLine: true,
        zoom: 'day',
        newIssueUrl: '',
        permissions: {
            issueCreation: true,
            issueRelationManagment: true
        }
    },

    RELATION_TYPES = {
        precedes:   {reverse: 'follows'},
        blocked:    {reverse: 'blocks'},
        duplicated: {reverse: 'duplicates'},

        follows:    {color: '#1111aa', visible: true},
        blocks:     {color: '#aa1111', visible: true},
        relates:    {color: '#11aa11'},
        duplicates: {color: '#000000'},
        copied_to:  {color: '#aa11aa'}
    };

    $.fn.easygantt = function (options, methodParams) {
        //init
        if(typeof options == 'object') {
            settings = $.extend(settings, options);
            if (!settings.relativeUrlRoot) {
                settings.relativeUrlRoot = '';
            }
            $.each(settings.holidays, function () {
                this.date = moment(this.date);
            });
            if (!/\/$/.test(settings.relativeUrlRoot)) {
                settings.relativeUrlRoot += '/'
            }
            gantt = new EasyGantt(this);
            $.data(this[0], 'gantt', gantt);
        }
        //method calling
        else if(typeof options == 'string') {
            gantt = $.data(this[0], 'gantt');
            switch(options) {
                case 'saveIssues':
                    gantt.saveIssues();
                    break;
                case 'reload':
                    gantt.reload();
                    break;
                case 'newIssue':
                    return gantt.newIssue();
                    break;
                case 'newMilestone':
                    return gantt.newMilestone();
                    break;
                case 'newMilestoneIssue':
                    gantt.newMilestoneIssue();
                    break;
                case 'newRelation':
                    if (typeof methodParams === 'string') {
                        return gantt.newRelation(methodParams);
                    } else {
                        return gantt.newRelation('follows');
                    }
                    break;
                case 'destroyRelation':
                    return gantt.destroyRelation();
                    break;
                case 'cancelNewRelation':
                    gantt.cancelNewRelation();
                    break;
            }
        }
        $('#modal-dialog-loader').css('overflow', 'hidden');
        return this;
    };

    function EasyGantt(container) {
        var self = this;
        this.settings = settings;
        this.container = container;
        this.gantt = $('<div/>').appendTo(this.container).addClass('easygantt').css('height', window.innerHeight - this.container[0].offsetTop - 100);
        this.width = this.gantt.width();
        this.userListContainer = $('<div/>').addClass('user-list-container').appendTo(this.gantt).resizable({
            stop: function (event, ui) {
                self.gridContainer.hide();
                setTimeout(function () {
                    self.afterSplitterResize();
                },100);
            },
            helper: 'easygantt-splitter',
            handles: 'e',
            minWidth: 180
        });

        this.userListScroller = $('<div/>')
            .addClass('user-list-scroller')
            .appendTo(this.userListContainer)
            .scroll(function (event) {
                self.afterUserListScroll(this, event);
            });

        $('#issues .ui-resizable-handle.ui-resizable-e:first').css('z-index', '35');

        this.userListScroller.css('height', this.gantt.height() - 2 * settings.rowHeight - 2);

        this.userList = $('<tbody/>').appendTo(
            $('<table/>').addClass('user-list').appendTo(this.userListScroller)
            );

        var gc = $('<div/>').addClass('grid-container').appendTo(this.gantt);
        this.gridHeaderContainer = $('<div/>').addClass('grid-header-container').appendTo(gc);
        this.gridHeader = $('<div/>').addClass('grid-header').appendTo(this.gridHeaderContainer);
        this.gridBodyContainer = $('<div/>').appendTo(gc).addClass('grid-body-container');
        this.gridBody = $('<div/>').addClass('grid-body').appendTo(this.gridBodyContainer).addClass(settings.zoom);
        this.gridContainer = gc;
        this.gridBodyContainer.css('height', this.gantt.height() - 2*settings.rowHeight);

        if(settings.zoom == 'week') {
            settings.dayWidth = 24 / 7;
        } else if(settings.zoom == 'month') {
            settings.dayWidth = 24 / 14;
        }

        this.loadData(settings.loadUrl, settings.loadParams);
        if (!settings.isProjectGantt) {
            this.createRelationLegend();
        }
    }

    EasyGantt.prototype.eachIssue = function (callback) {
        $.each(this.groups, function () {
            $.each(this.issues, function () {
                if(!this.milestone) {
                    return callback.call(this);
                }
            });
        });
    };

    EasyGantt.prototype.plumbing = function () {
        var opts = epOptions();
        var self = this;
        jsPlumb.bind('jsPlumbConnection', function (con) {
            if(!self.isReloading) {
                var issueTo = self.findIssueByTargetId(con.source.attr('id'));
                var issueFrom = self.findIssueByTargetId(con.target.attr('id'));
                self.createRelation(issueFrom, issueTo, self.currentRelationType);
            }
        });
    };

    EasyGantt.prototype.afterSplitterResize = function () {
        this.gridContainer.css('width', this.gantt.width() - (this.userListScroller.outerWidth() + 5)).show();
        this.userListScroller[0].scrollTop = 0;
    };

    EasyGantt.prototype.createCalendar = function () {

        var d = this.start.clone();

        var mc;
        var monthDiv;
        var daysDiv;
        var w = parseInt(this.gridHeader.css('width'));
        this.addDays(parseInt(w/this.settings.dayWidth) + 2);
        if(this.settings.todayLine) this.createTodayLine();

        var bgPos = getDatePosition(this.start.clone().day(8), this);
        this.gridBody.css('background-position-x', bgPos).css('background-position', bgPos + 'px 0');

    };

    EasyGantt.prototype.createTodayLine = function () {
        this.todayLine = $('<div/>').html('&nbsp;').addClass('todayLine').css('left', getDatePosition(moment().add(-1, 'day'), this) + settings.dayWidth / 2);
        if(this.end < moment()) this.todayLine.hide();
        this.gridBody.append(this.todayLine);
    };

    EasyGantt.prototype.clean = function () {
        this.gridHeader.empty();
        this.gridBody.empty();
        this.userList.empty();

        this.groups = [];
        this.relations = [];
        this.start = null;
        this.end = null;
        this.data = null;
        this.monthContainer = null;
        this.weekContainer = null;
        this.todayLine = null;
    }

    EasyGantt.prototype.loadData = function (url) {
        var gantt = this;
        this.groups = [];
        this.relations = [];
        this.issueColumns = [];
        $.getJSON(url, getEasyQueryFiltersForURL(''), function (data) {
            data = data.ganttdata;
            gantt.processData(data);
            gantt.scrollToToday();
            if(!gantt.isReloading) gantt.plumbing();
            gantt.isReloading = false;
        });
    }

    EasyGantt.prototype.newIssue = function (urlParams, reloadOnCancel) {
        if (!this.checkUnsavedChanges()) {
            return false;
        }
        var gantt = this;
        if(this.newIssueDialog) this.newIssueDialog.remove();
        this.newIssueDialog = $('<div/>').addClass('gantt-new-issue-container').appendTo('body');
        $.get(this.settings.newIssueUrl, urlParams, function (data) {
            var self = gantt.newIssueDialog.html(data);
            var dialogButtons = {};
            dialogButtons[gantt.settings.lang.createIssue] = function () {
                gantt.createIssue();
            };
            dialogButtons[gantt.settings.lang.createIssueAndContinue] = function () {
                gantt.createIssue({again: true, urlParams: urlParams});
            };
            dialogButtons[gantt.settings.lang.cancel] = function () {
                self.dialog('close').remove();
                if(reloadOnCancel) gantt.reload();
            };
            self.dialog({width: 727, buttons: dialogButtons});
        });
        return true;
    };

    EasyGantt.prototype.newMilestone = function () {
        var title,
            gantt = this;
        if (!this.checkUnsavedChanges()) {
            return false;
        }
        if (this.newMilestoneDialog) {
            this.newMilestoneDialog.remove();
        }
        this.newMilestoneDialog = $('<div/>').addClass('gantt-new-milestone-container').appendTo('body');
        $.get(this.settings.newMilestoneUrl, function (data) {
            var self = gantt.newMilestoneDialog.html(data),
                dialogButtons = {};
            dialogButtons[gantt.settings.lang.createMilestone] = function () {
                gantt.createMilestone();
            };
            dialogButtons[gantt.settings.lang.cancel] = function () {
                self.dialog('close').remove();
            };

            title = $('h2', gantt.newMilestoneDialog).text();
            $('h2, a.icon-add, .milestone-sharing-info, #relations, input[type="submit"]', gantt.newMilestoneDialog).remove();

            self.dialog({title: title, width: 727, buttons: dialogButtons});
        });
        return true;
    };

    EasyGantt.prototype.newMilestoneIssue = function (milestoneId) {
        this.newIssue('issue[fixed_version_id]=' + milestoneId);
    };

    EasyGantt.prototype.createIssue = function (options) {
        if (!options) options = {};
        var self = this;
        var dialog = this.newIssueDialog;
        var f = $('#issue-form', dialog);
        if(f.length == 0) {dialog.dialog('close').remove(); return;}

        $("#issue_description", f).val(CKEDITOR.instances.easy_modalissue_description.getData());

        $.post(f.attr('action'), f.serialize(), function (resp) {
            var issueId = parseInt(resp);
            if (isNaN(issueId)) {
                dialog.html(resp);
            } else {
                dialog.dialog('close').remove();
                if(options.again) {
                    self.newIssue(options.urlParams, true);
                } else {
                    self.scrollToIssueId = issueId;
                    self.reload();
                }
            }
        });
    };

    EasyGantt.prototype.createMilestone = function () {
        var description = 'version_description',
            self = this,
            dialog = this.newMilestoneDialog,
            f = $("form", dialog);

        $('#version_description').val(CKEDITOR.instances[description].getData());

        $.post(f.attr('action'), f.serialize(), function (resp) {
            resp = $(resp);
            if ($('#errorExplanation', resp).length > 0) {
                $('#errorExplanation', dialog).remove();
                $('#errorExplanation', resp).prependTo(dialog);
            } else {
                dialog.dialog('close').remove();
                self.reload();
            }
        });

    };

    EasyGantt.prototype.checkUnsavedChanges = function () {
        var movedItems = this.getMovedItems();
        if (movedItems.length > 0) {
            if (confirm(settings.lang.confirmUnsavedChanges)) {
                return true;
            } else {
                return false;
            }
        }
        return true;
    };

    EasyGantt.prototype.newRelation = function (relationType) {
        if (!this.checkUnsavedChanges()) {
            return false;
        }
        this.currentRelationType = relationType;
        this.eachIssue(function () {
            if(!this.worm) return;
            var opts = epOptions();
            // connectorStyle: {strokeStyle: '#1111aa', lineWidth: 1},
            opts.connectorStyle.strokeStyle = RELATION_TYPES[relationType].color;
            // jsPlumb.makeSource(this.worm[0], $.extend(opts, {anchor: "RightMiddle"}));
            this.newRelConOut = jsPlumb.addEndpoint(this.worm, $.extend(opts, {
                endpoint: 'Dot',
                isSource: true,
                anchor: "RightMiddle",
                paintStyle: {radius: 6, fillStyle: '#333'}
            }));
            this.newRelConIn = jsPlumb.addEndpoint(this.worm, $.extend(opts, {
                endpoint: 'Dot',
                isTarget: true,
                anchor: "LeftMiddle",
                paintStyle: {radius: 6, fillStyle: '#333'}
            }));
            jsPlumb.makeTarget(this.worm[0], $.extend(opts, {anchor: "LeftMiddle"}));
            if (!this.editable) {
                this.worm.draggable('disable').resizable('disable');
            }
        });
        this.gantt.addClass('new-relation');
        return true;
    };

    EasyGantt.prototype.destroyRelation = function () {
        if (!this.checkUnsavedChanges()) {
            return false;
        }
        this.destroyingRelations = true;
        $.each(this.relations, function () {
            this.connection.addOverlay(['Diamond', {location: 0.5, width: 10, length: 10}], true);
            this.connection.setHoverPaintStyle({strokeStyle: '#ff0000'});
        });
        return true;
    };

    EasyGantt.prototype.cancelNewRelation = function () {
        this.destroyingRelations = false;
        this.reload();
        this.gantt.removeClass('new-relation');
    };

    EasyGantt.prototype.createRelation = function (from, to, relationType) {
        var self = this,
            params = {'relation[relation_type]': relationType || 'precedes', format: 'json'};

        params['relation[issue_to_id]'] = to.id;
        if (relationType === 'follows') {
            params['relation[delay]'] = Math.max(countDays(to.end, from.start), 1);
        }
        $.ajax({
            type: 'post',
            url: settings.relativeUrlRoot + 'issues/' + from.id + '/relations',
            data: params,
            complete: function (jqXHR, resp) {
                if(jqXHR.status === 422) {
                    flash('error', $.parseJSON(jqXHR.responseText).errors.join('\n'));
                }
                self.reload();
            }
        });
        this.gantt.removeClass('new-relation');
        $('.gantt-relation').toggle();
    };

    EasyGantt.prototype.findIssueByEndpointId = function (epId) {
        var issue = null;
        this.eachIssue(function () {
            if(!this.worm) return;
            if(this.connectorIn.id && this.connectorIn.id == epId) {issue = this; return false;}
            if(this.connectorOut.id && this.connectorOut.id == epId) {issue = this; return false;}
        });
        return issue;
    };

    EasyGantt.prototype.findIssueByTargetId = function (targetId) {
        var issue = null;
        this.eachIssue(function () {
            if(this.worm && this.worm.attr('id') == targetId) {issue = this; return false;}
        });
        return issue;
    };

    EasyGantt.prototype.reload = function () {
        var self = this;
        this.isReloading = true;
        this.gantt.empty();
        this.monthContainer = null;
        this.weekContainer = null;
        this.daysDiv = null;
        this.start = null;
        this.end = null;
        this.groups = null;
        this.issues = null;
        this.issueColumnHeader = null;
        jsPlumb.deleteEveryEndpoint();
        this.gantt.css('height', window.innerHeight - this.container[0].offsetTop - 100);
        this.width = this.gantt.width();
        this.userListContainer = $('<div/>').addClass('user-list-container').appendTo(this.gantt).resizable({
            stop: function (event, ui) {
                self.gridContainer.hide();
                setTimeout(function () {
                    self.afterSplitterResize();
                }, 100);
            },
            helper: 'easygantt-splitter',
            handles: 'e',
            minWidth: 180
        });
        this.userListScroller = $('<div/>').addClass('user-list-scroller').appendTo(this.userListContainer);
        $('#issues .ui-resizable-handle.ui-resizable-e:first').css('z-index', '35');
        this.userListScroller.css('height', this.gantt.height() - 2 * settings.rowHeight - 2);
        this.userList = $('<tbody/>').appendTo(
            $('<table/>').addClass('user-list').appendTo(this.userListScroller)
            );

        var gc = $('<div/>').addClass('grid-container').appendTo(this.gantt);
        this.gridHeaderContainer = $('<div/>').addClass('grid-header-container').appendTo(gc);
        this.gridHeader = $('<div/>').addClass('grid-header').appendTo(this.gridHeaderContainer);
        this.gridBodyContainer = $('<div/>').appendTo(gc).addClass('grid-body-container');
        this.gridBody = $('<div/>').addClass('grid-body').appendTo(this.gridBodyContainer).addClass(settings.zoom);
        this.gridContainer = gc;
        this.gridBodyContainer.css('height', this.gantt.height() - 2*settings.rowHeight);

        if(settings.zoom == 'week') {
            settings.dayWidth = 24/7;
        } else if(settings.zoom == 'month') {
            settings.dayWidth = 24/14;
        }

        $('div.qtip').remove();
        this.loadData(settings.loadUrl);
    };

    EasyGantt.prototype.scrollToToday = function () {
        return false;
        this.gridBodyContainer[0].scrollLeft = getDatePosition(moment(), this) - 3*settings.dayWidth;
        this.gridBodyContainer.scroll();
    };

    EasyGantt.prototype.afterScroll = function (el, event) {
        var scrollRatio = ($(el).scrollLeft() + $(el).width()) / this.gridBody.width();
        if(scrollRatio > 0.94) this.addDays(7);
        $(this.gridHeaderContainer)[0].scrollLeft = el.scrollLeft;
        $(this.userListScroller)[0].scrollTop = el.scrollTop;
    };

    EasyGantt.prototype.afterUserListScroll = function (el, event) {
        if (this.issueColumnHeaderScroller) {
            this.issueColumnHeaderScroller[0].scrollLeft = el.scrollLeft;
        }
    }

    EasyGantt.prototype.processData = function (data) {
        var gantt = this;
        if(!data) return;
        if(data.start) {
            this.start = moment(data.start);
            if(settings.zoom != 'day') {
                this.start.day(-8);
                this.start.date(1);
                this.start.day(8);
                this.end = this.start.clone().day(1);
            } else {
                this.start.subtract(1, 'days');
                this.end = this.start.clone().subtract(1, 'day');
            }
        }

        if (data.columns) {
            $.each(data.columns, function () {
                gantt.issueColumns.push(this.name);
            });
        }

        this.createCalendar();

        this.gridBodyContainer.scroll(function (event) {
            gantt.afterScroll(this, event);
        });

        if(data.project) this.project = new Project(data.project, this);
        if(data.projects && data.projects.constructor == Array) this.createProjects(data.projects)

            var rowCount = 0;

        if(typeof data.issue_groups == 'object' && data.issue_groups.constructor == Array) {
            for (var i = 0; i < data.issue_groups.length; i++) {
                if (data.issue_groups[i].project) {
                    this.groups.push(new Project(data.issue_groups[i], this, rowCount))
                } else {
                    this.groups.push(new Group(data.issue_groups[i], this))
                }
                rowCount += this.groups[this.groups.length - 1].issues.length;
                if(!this.groups[this.groups.length - 1].data.hidden_group) rowCount++;
            }
        }
        if(this.project) rowCount++;
        if(this.projects) rowCount += this.projects.length;
        this.gridBody.css('height', settings.rowHeight * rowCount);
        if(this.gridBodyContainer.height() > (rowCount + 3.5)*settings.rowHeight) {
            this.setHeight((rowCount + 3.5)*settings.rowHeight);
        }

        if (this.issueColumns.length > 0) {
            this.createIssueColumnHeader();
        } else {
            this.userListScroller.css('margin-top', 2 * settings.rowHeight);
        }

        this.connectRelations();

        if(this.scrollToIssueId) {
            this.scrollToIssue(this.scrollToIssueId);
            this.scrollToIssueId = null;
        }
    }

    EasyGantt.prototype.createIssueColumnHeader = function () {
        var self = this,
            issueColumnWidths = [],
            thead, tr;

        $('tr.issue-menu-item:first td', this.userList).each(function() {
            issueColumnWidths.push($(this).outerWidth());
        });

        this.issueColumnHeaderScroller = $('<div/>')
            .addClass('issue-column-header-scroller')
            .prependTo(this.userListContainer);

        this.issueColumnHeader = $('<table/>')
            .css('margin-top', settings.rowHeight + 4)
            .addClass('issue-column-header')
            .css('width', this.userList.parent().width())
            .appendTo(this.issueColumnHeaderScroller);

        thead = $('<thead/>').appendTo(this.issueColumnHeader);
        tr = $('<tr/>')
                .css('height', settings.rowHeight)
                .appendTo(thead).append($('<th/>'));


        $.each(this.issueColumns, function (i) {
            tr.append('<th>' + this + '</th>')
        });

        tr.children().each(function() {
            $(this).css('width', issueColumnWidths.shift() || 0)
        });
    };

    EasyGantt.prototype.scrollToIssue = function (issue) {
        if(typeof issue == 'number') issue = this.findIssue(issue);
        if(issue && issue.worm) {
            this.gridBodyContainer.scrollTop(issue.worm.position().top - 10).scrollLeft(issue.worm.position().left - 10);
        }
    };

    EasyGantt.prototype.setHeight = function (h) {
        this.gantt.css('height', h);
        this.userListScroller.css('height', this.gantt.height() - 2*settings.rowHeight);
        this.gridBodyContainer.css('height', this.gantt.height() - 2*settings.rowHeight);
    }

    EasyGantt.prototype.createProjects = function (data) {
        this.projects = [];
        for(var i = 0; i < data.length; i++) {
            this.projects.push(new Project(data[i], this, i));
        }
    }

    EasyGantt.prototype.addDays = function (n) {
        if(settings.zoom == 'day') {
            for(var i = 0; i < n; i++) this.addDay();
                while(this.end.clone().add(1, 'day').date() != 1) {
                    this.addDay();
                }
            } else {
                for(var i = 0; i < n; i += 7) {
                    this.addWeek();
                }
            }
        }

        EasyGantt.prototype.addWeek = function () {
            var newEnd = this.end.clone().add('days', 7);
            var daysDiv;
            if(!this.monthContainer) {
                this.monthContainer = $('<div/>')
                .addClass('month-container-small')
                .appendTo(this.gridHeader);
            }
            if(!this.weekContainer) {
                this.weekContainer = $('<div/>')
                .addClass(settings.zoom == 'week' ? 'week-container' : 'week-container-small')
                .appendTo(this.gridHeader);
            }
            if(newEnd.month() != this.end.month() || this.monthContainer.is(':empty')) {
                var m = $('<span/>')
                .html((settings.zoom == 'week' ? settings.lang.monthNames[newEnd.month()] : newEnd.month()) + newEnd.format(" 'YY"))
                .appendTo(this.monthContainer);

                if(newEnd.isSame(this.start, 'day')) {
                    m.css('width', this.monthWidth(newEnd));
                } else {
                    var firstDayOfMonth = newEnd.clone();
                    firstDayOfMonth.date(1);
                    m.css('width', this.monthWidth(firstDayOfMonth));
                }
            }

            $('<span/>')
            .html(newEnd.week())
            .appendTo(this.weekContainer);

            this.gridHeader.css('width', this.weekContainer.children().length * settings.dayWidth * 7);
            this.gridBody.css('width', this.gridHeader.css('width'));
            this.end = newEnd;
            if(this.todayLine && this.end > moment()) this.todayLine.show();
        }

        EasyGantt.prototype.monthWidth = function (x) {
            var date = moment(new Date(x.year(), x.month() + 1, 0));
            return (date.date() + 1 - x.date()) * settings.dayWidth;
        }

        EasyGantt.prototype.addDay = function () {
            var newEnd = this.end.clone().add(1, 'days');
            var daysDiv;
            if(newEnd.month() == this.end.month() && $('div.days:last', this.gridHeader).length > 0) {
                daysDiv = $('div.days:last', this.gridHeader);
            }
            else {
                mc = $('<div/>').addClass('month-container').appendTo(this.gridHeader);
                monthDiv = $('<div/>').addClass('month').appendTo(mc);
                if(newEnd.date() < 20) monthDiv.append(newEnd.year() + '/' + (newEnd.month() + 1));
                daysDiv = $('<div/>').addClass('days').appendTo(mc);
            }

            this.gridHeader.css('width', (countDays(this.start, newEnd) + 1) * settings.dayWidth);
            this.gridBody.css('width', this.gridHeader.css('width'));


            var ds = $('<span/>').append(newEnd.date()).appendTo(daysDiv);
            if(!isWorkingDay(newEnd)) ds.addClass('weekend');
            if(this.todayLine && newEnd > moment()) this.todayLine.show();

            this.end = newEnd;

        }

        EasyGantt.prototype.getMovedItems = function () {
            var movedItems = [];
            for (var i = 0; i < this.groups.length; i++) {
                var g = this.groups[i];
                for (var j = 0; j < g.issues.length; j++) {
                    var entity = g.issues[j];
                    if(entity.moved) {
                        if(entity.milestone)
                            movedItems.push({
                                type: 'milestone',
                                id: entity.id,
                                date: getPositionDate(entity.position, this).format(settings.dateFormat),
                            });
                        else {
                            movedItems.push({
                                type: 'issue',
                                id: entity.id,
                                start: getPositionDate(entity.position, this).format(settings.dateFormat),
                                end: getPositionDate(entity.position + entity.width, this).subtract(1, 'day').format(settings.dateFormat)
                            });
                        }
                    }
                };
            };
            if(this.project && this.project.moved) {
                movedItems.push(this.project.toData());
            }

            if(this.projects) {
                for(var i = 0; i < this.projects.length; i++) {
                    if(this.projects[i].moved) movedItems.push(this.projects[i].toData());
                }
            }
            return movedItems;
        };

        EasyGantt.prototype.saveIssues = function () {
            var movedItems = this.getMovedItems(),
                gantt = this;
            $.post(settings.saveIssuesUrl, {items: movedItems}, function (response) {
                gantt.isReloading = true;
                settings.saveCallback(response);
                gantt.reload();
            });
        };

        EasyGantt.prototype.findIssue = function (id) {
            var issue = null;
            for(var i = 0; i < this.groups.length; i++) {
                issue = this.groups[i].findIssue(id);
                if(issue) break;
            }
            return issue;
        };

        EasyGantt.prototype.connectRelations = function () {
            if (getInternetExplorerVersion().toString() !== '8') {
                this.eachIssue(function () {
                    this.connectRelations();
                });
            }
        };

        EasyGantt.prototype.createRelationLegend = function () {
            var that = this,
            legendIcon, legend;

            this.relationLegend = $('<div/>').insertAfter(this.container).addClass('gantt-relation-legend');

            $.each(RELATION_TYPES, function (i) {
                if (!this.reverse) {
                    if (settings.visibleRelations.indexOf(i) >= 0) {
                        this.visible = true;
                    } else {
                        this.visible = false;
                    }
                    legendIcon = $('<span/>')
                    .addClass('legend-icon')
                    .css('background-color', this.color);

                    if (this.visible) {
                        legendIcon.addClass('checked').html('&#10003;');
                    }
                    legend = $('<span/>').append(legendIcon).append(settings.lang[i]).appendTo(that.relationLegend).click(function () {
                        legendIcon = $(this).children('span.legend-icon');
                        if (legendIcon.hasClass('checked')) {
                            legendIcon.empty().removeClass('checked');
                        } else {
                            legendIcon.html('&#10003;').addClass('checked');
                        }
                        $.post(settings.relativeUrlRoot + 'users/save_button_settings', {
                            uniq_id: 'easy_gantt_relation_' + i,
                            open: legendIcon.hasClass('checked')
                        });
                        that.loadRelationVisibility();
                        that.updateRelationVisibility();
                    });
                    $.data(legend[0], 'relationType', i);
                }
            });
};

EasyGantt.prototype.loadRelationVisibility = function () {
    this.relationLegend.children().each(function () {
        if ($('span.checked', this).length === 0) {
            RELATION_TYPES[$.data(this, 'relationType')].visible = false;
        } else {
            RELATION_TYPES[$.data(this, 'relationType')].visible = true;
        }
    });
};

EasyGantt.prototype.updateRelationVisibility = function () {
    this.eachIssue(function () {
        $.each(this.relationsTo, function () {
            if(this.isVisible()) {
                this.show();
            } else {
                this.hide();
            }
        });
    });
};

function Group(groupData, gantt) {
    this.data = groupData;
    this.gantt = gantt;
    this.rowIndex = gantt.project ? 1 : 0;
    if(!this.data.hidden_group) {
        for(var i = 0; i < gantt.groups.length; i++) {
            this.rowIndex += 1 + gantt.groups[i].issues.length;
        }
    } else {
        this.rowIndex--;
    }
    this.createMenuItem();
    this.issues = [];
    this.createIssues();
}

Group.prototype.createMenuItem = function () {
    this.menuItem = $('<tr/>').appendTo(this.gantt.userList).addClass('group-menu-item');
    if(!this.data.hidden_group) {
        var nameFromColumns;
        if(this.data.columns && this.data.columns.length > 0) nameFromColumns = this.data.columns.join(' / ');
        this.menuItem.append(
            $('<td/>').attr('colspan', gantt.issueColumns.length + 1).append(
                $('<a/>').attr('href', this.data.link || 'javascript:void(0);').html(nameFromColumns || this.data.name)
                )
            );
    } else {
        this.menuItem.hide();
    }
    var currentGroup = this;
    var settings = this.gantt.settings;
    if(this.data.issues.length == 0) {
        this.menuItem.addClass('no-issues');
    } else if(!this.data.hidden_group){
        this.expander = $('<span/>').html('&nbsp;').addClass('expander open').prependTo($('td:first', this.menuItem)).click({group: this}, function (e) {
            var positionCorrection = e.data.group.issues.length * settings.rowHeight;
            if(e.data.group.expander.hasClass('open')) {
                for (var i = 0; i < e.data.group.issues.length; i++) {
                    var issue = e.data.group.issues[i];
                    issue.hide();
                }
                positionCorrection *= -1;
            } else {
                for (var i = 0; i < e.data.group.issues.length; i++) {
                    var issue = e.data.group.issues[i];
                    issue.show();
                }
            }
            e.data.group.issues[0].worm.nextAll().each(function () {
                var correctedPosition = parseFloat($(this).css('top')) + positionCorrection;
                $(this).css('top', correctedPosition);
            });
            e.data.group.expander.toggleClass('open');
            jsPlumb.repaintEverything();
        });
}
}

Group.prototype.parseIssuesData = function () {
    for (var i = 0; i < this.data.issues.length; i++) {
        this.data.issues[i].rowIndex = 1 + this.rowIndex + i;
        this.data.issues[i].milestone = !!this.data.issues[i].milestone;
        if(this.data.issues[i].milestone) {
            this.data.issues[i].date = moment(this.data.issues[i].date);
        } else {
            this.data.issues[i].start = moment(this.data.issues[i].start);
            this.data.issues[i].end = moment(this.data.issues[i].end);
        }
    }
}

Group.prototype.createIssues = function () {
    if(this.data.issues && this.data.issues.length > 0) {
        this.issueMenu = this.menuItem.parent();
        this.parseIssuesData();
        for (var i = 0; i < this.data.issues.length; i++) {
            var entity;
            if(this.data.issues[i].milestone) entity = new Milestone(this.data.issues[i], this);
            else {
                entity = new Issue(this.data.issues[i], this);
                entity.createAdditionalColumns();
            }
            this.issues.push(entity);
        }
    }
}

Group.prototype.findIssue = function (id) {
    for (var i = 0; i < this.issues.length; i++) {
        if(this.issues[i].id == id) return this.issues[i];
    }
    return null;
}
function Project(projectData, gantt, rowIndex) {
    this.data = projectData;
    this.gantt = gantt;
    this.id = projectData.id;
    this.rowIndex = rowIndex || 0;
    if(this.data.start) this.start = moment(this.data.start);
    if(this.data.end) {
        this.end = moment(this.data.end);
        if(this.gantt.end < this.end) {
            this.gantt.addDays(countDays(this.gantt.end, this.end));
        }
    }

    this.createMenuItem();
    this.children = [];

    this.issues = [];
    this.createIssues();

    if(!this.data.noworm) {
        this.createWorm();
        var prg = $('<div/>').appendTo(this.worm)
        .addClass('progress')
        .css('width', this.data.percentcompleted + '%');
        if(this.data.versions) {
            this.createInlineMilestones();
        }
    }
    Project.parents.push(this);
}

    // inheritance
    Project.prototype.createIssues = Group.prototype.createIssues;
    Project.prototype.parseIssuesData = Group.prototype.parseIssuesData;
    Project.prototype.findIssue = Group.prototype.findIssue;

    Project.parents = [];

    Project.prototype.toData = function () {
        return {
            type: 'project',
            id: this.id,
            start: getPositionDate(this.worm.position().left, this.gantt).format(settings.dateFormat),
            end: getPositionDate(this.worm.position().left + this.worm.width(), this.gantt).subtract(-1, 'day').format(settings.dateFormat)
        }
    }

    Project.prototype.createMenuItem = function () {
        while(Project.parents.length > 0 && Project.parents[Project.parents.length - 1].id != this.data.parentid) {
            var p = Project.parents.pop();
        }

        this.menuItem = $('<tr/>')
            .addClass('group-menu-item')
            .append($('<td/>')
                .append($('<a/>')
                    .attr('href', this.data.link || 'javascript:void(0);')
                    .html(this.getLevelPrefix() + this.data.name)
                )
                .attr('colspan', gantt.issueColumns.length + 1)
            );

        if(Project.parents.length > 0) {
            var parent = Project.parents[Project.parents.length - 1];
            parent.addChildMenuItem(this.menuItem);
            parent.children.push(this);
        }
        else {
            this.menuItem.appendTo(this.gantt.userList);
        }
    }

    Project.prototype.getLevelPrefix = function () {
        var prefix = '';
        for(var i = 0; i < this.data.level; i++) prefix += '&nbsp;&nbsp;';
            return prefix;
    };

    Project.prototype.createWorm = function () {
        var self = this;
        this.container = $('<div/>')
        .css('left', 0)
        .css('width', '100%')
        .css('height', settings.rowHeight)
        .css('position', 'absolute')
        .css('top', this.rowIndex * settings.rowHeight)
        .appendTo(this.gantt.gridBody);
        this.worm = $('<div/>').addClass('worm project').appendTo(this.container)
        .css('width', (1 + countDays(this.start, this.end))*settings.dayWidth)
        .css('left', getDatePosition(this.start, this.gantt))
        .draggable({
            axis: 'x',
            containment: 'parent',
            stop: function (event, ui) {
                var lft = parseInt(self.worm.css('left'));
                lft = Math.round(lft/settings.dayWidth) * settings.dayWidth;
                self.worm.css('left', lft);
                self.moved = true;
            }
        })
        .resizable({
            handles: 'e',
            grid: [settings.dayWidth, settings.rowHeight],
            minWidth: settings.dayWidth,
            stop: function () {
                self.moved = true;
            }
        });
    };

    Project.prototype.createInlineMilestones = function () {
        this.inlineMilestones = [];
        for (var i = this.data.versions.length - 1; i >= 0; i--) {
            this.inlineMilestones.push(new InlineMilestone(this.data.versions[i], this));
        };
    };

    function InlineMilestone(data, project) {
        this.project = project;
        for(p in data) this[p] = data[p];
            this.date = moment(this.date);
        this.createRhombus();
    }

    InlineMilestone.prototype.createRhombus = function () {
        this.rhombus = $('<div/>')
        .addClass('inline-milestone')
        .appendTo(this.project.worm)
        .css('left', this.getPosition())
        .css('top', 0)
        .qtip({
            style: 'fwe',
            content: this.tooltipContent()
        });
    };

    InlineMilestone.prototype.tooltipContent = function () {
        return $('<div/>')
        .append('<h5>' + this.project.data.name + '</h5>')
        .append('<h6>' + this.name + '</h6>')
        .append('<p><strong>' + settings.lang.status + ': </strong>' + this.status)
        .append('<p><strong>' + settings.lang.date + ': </strong>' + formatDate(this.date) + '</p>')
        .append('<p><strong>' + settings.lang.category + ': </strong>' + (this.category || ''));
    };

    InlineMilestone.prototype.getPosition = function () {
        var projectLength = this.project.end - this.project.start;
        var absolutePosition = this.date - this.project.start;
        return (100*absolutePosition/projectLength) + '%';
    };


    function Issue(issueData, group) {
        var self = this;
        this.group = group;
        this.relationsTo = [];
        this.relationsFrom = [];
        for(p in issueData) {
            this[p] = issueData[p];
        }
        if (this.start && !this.end) this.end = this.start.clone();
        if (this.end && !this.start) this.start = this.end.clone();

        this.createMenuItem();

        if (settings.permissions.issueRelationManagment && settings.permissions.issueCreation) {
            this.createContextMenu();
            this.bindContextMenuEvents();
        }

        if(this.start && this.end) {
            this.position = getDatePosition(this.start, this.group.gantt);
            this.width = (1 + countDays(this.start, this.end))*settings.dayWidth;
            this.createWorm();

            var prg = $('<div/>').appendTo(this.worm)
            .addClass('progress')
            .css('width', this.percentcompleted + '%');

            if(this.group.gantt.end < this.end) {
                this.group.gantt.addDays(countDays(this.group.gantt.end, this.end));
            }
        }

        if(this.est) {
            this.minWidth = Math.ceil(this.est/8) * settings.dayWidth
        }
    }

    Issue.prototype.hide = function () {
        this.menuItem.hide();
        this.worm.hide();
        this.isHidden = true;

        $.each(this.relationsTo, function () {
            this.hide();
        });
        $.each(this.relationsFrom, function () {
            this.hide();
        });
    };

    Issue.prototype.show = function () {
        this.menuItem.show();
        this.worm.show();
        this.isHidden = false;

        $.each(this.relationsTo, function () {
            if (this.isVisible()) {
                this.show();
            }
        });
        $.each(this.relationsFrom, function () {
            if (this.isVisible()) {
                this.show();
            }
        });
    };

    Issue.prototype.createMenuItem = function () {
        var name = '';
        for(var i = 0; i < this.level; i++) name += '&nbsp;&nbsp;&nbsp;&nbsp;';
            name += this.name;
        this.menuItem = $('<tr/>')
        .append(
            $('<td/>').append(
                $('<a/>').html(name)
                .attr('href', this.link || 'javascript:void(0);')
                .attr('title', this.name)
                )
            )
        .appendTo(this.group.issueMenu)
        .addClass('issue-menu-item');

        if(typeof this.css_classes == 'string') {
            this.menuItem.addClass(this.css_classes);
        }
    }

    Issue.prototype.createAdditionalColumns = function () {
        if(!this.columns) {
            $('td:first', this.menuItem).attr('colspan', 1000);
        } else {
            for(var i = 0; i < this.columns.length; i++) {
                var col = this.columns[i];
                this.menuItem.append('<td>' + col + '</td>');
            }
        }
    }

    Issue.prototype.createContextMenu = function () {
        this.contextMenu = $('<ul/>').addClass('gantt-context-menu');
        var self = this;

        $('<a/>').attr('href', 'javascript:void(0)').html(l(this, 'newFollowingIssue')).click(function () {
            self.newFollowingIssue();
        }).appendTo($('<li/>').appendTo(this.contextMenu));

        $('<a/>').attr('href', 'javascript:void(0)').html(l(this, 'newPrecedingIssue')).click(function () {
            self.newPrecedingIssue();
        }).appendTo($('<li/>').appendTo(this.contextMenu));

        $('<a/>').attr('href', 'javascript:void(0)').html(l(this, 'newChildIssue')).click(function () {
            self.newChildIssue();
        }).appendTo($('<li/>').appendTo(this.contextMenu));
    };

    Issue.prototype.bindContextMenuEvents = function () {
        var self = this;
        this.menuItem.qtip({
            effect: 'none',
            content: this.contextMenu,
            delay: 0,
            style: {
                classes: 'gantt-ctx'
            },
            position: {
                target: 'mouse',
                adjust: {mouse: false}
            },
            show: 'mouseup',
            hide: {
                target: $(document),
                event: 'foobar'
            },
            events: {
                show: function (e) {
                    $('.qtip').each(function (){
                     $(this).qtip('hide');
                     $(this).removeClass('highlight');
                 });
                    if(e.originalEvent.button !== 2) {
                        return false;
                    } else {
                        self.menuItem.addClass('highlight');
                    }
                },
                hide: function (e) {
                    self.menuItem.removeClass('highlight');
                }
            }
        });
        this.menuItem.bind('contextmenu', function (event) {
            event.stopPropagation();
            event.preventDefault();
            return false;
        });
        this.menuItem.children().bind('contextmenu', function (event) {
            event.stopPropagation();
            event.preventDefault();
            return false;
        });
        this.menuItem.bind('mouseup', function (event) {
            self.menuItem.qtip('hide');
        });
        $(document).click(function () {
            self.menuItem.qtip('hide');
        });
    };

    Issue.prototype.newFollowingIssue = function () {
        this.group.gantt.newIssue('issue[relation][relation_type]=follows&issue[relation][issue_to_id]=' + this.id );
    };

    Issue.prototype.newPrecedingIssue = function () {
        this.group.gantt.newIssue('issue[relation][relation_type]=precedes&issue[relation][issue_to_id]=' + this.id );
    };

    Issue.prototype.newChildIssue = function () {
        this.group.gantt.newIssue({
            subtask_for_id: this.id
        });
    };

    Issue.prototype.isParent = function () {
        return !!this.parent;
    };

    Issue.prototype.createWorm = function () {
        var self = this;
        this.worm = $('<div/>').addClass('worm').appendTo(this.group.gantt.gridBody);
        this.worm
        .css('top', this.rowIndex * settings.rowHeight)
        .css('width', this.width)
        .css('left', this.position)
        .qtip({
            style: 'fwe',
            content: this.tooltipContent(),
            position: {
                target: 'mouse',
                adjust: {
                    x: 10,
                    y: 10,
                    mouse: false
                }
            },
            show: {
                delay: 100
            },
            hide: {
                event: 'click mouseleave',
                target: $.merge($(document), self.worm)
            }
        });
        var opts = epOptions();

        this.connectorOut = jsPlumb.addEndpoint(this.worm, $.extend(opts, {isSource: true, isTarget: false, anchor: "RightMiddle", connector:[ "Flowchart", { stub:[8, 8], alwaysRespectStubs:true } ]}));
        this.connectorIn = jsPlumb.addEndpoint(this.worm, $.extend(opts, {isSource: false, isTarget: true, anchor: "TopLeft"}));
        this.connectorUniversal = jsPlumb.addEndpoint(this.worm, {
            isSource: true,
            isTarget: true,
            paintStyle: {radius: 0, fillStyle: '#ffffff'},
            connectorStyle: {strokeStyle: "#4A8F43", lineWidth: 1},
            endpoint: 'Blank',
            maxConnections: 1000,
            connector: ['Bezier', {curviness: 50}],
            reAttachConnections: true
        });
        if (this.isParent()) {
            this.worm.addClass('parent-worm');
        }
        if (settings.allowParentIssueMovement || !this.isParent()) {
            jsPlumb.draggable(this.worm, {
                axis: 'x',
                containment: 'parent',
                grid:[settings.dayWidth, settings.rowHeight],
                start: function () {
                    $(this).qtip('hide').qtip('disable');
                },
                stop: function (event, ui) {
                    var positions = self.moveFromWeekends(ui.position.left);
                    self.moveRelations(positions.current.position - positions.original.position + (positions.current.width - positions.original.width), true);
                    jsPlumb.repaint(ui.helper);
                    $(this).qtip('enable');
                    self.moved = true;
                    self.position = positions.current.position;
                    self.width = positions.current.width;
                    self.validate();
                },
                drag: function (event, ui) {
                    self.moveRelations(ui.position.left - self.position);
                    jsPlumb.repaint(ui.helper);
                }
            });
            this.worm.resizable({
                handles: 'e',
                containment: 'parent',
                grid: [settings.dayWidth, settings.rowHeight],
                resize: function (event, ui) {
                    if(self.maxPosition && self.maxPosition < (ui.position.left + ui.size.width)) {
                        ui.size.width = self.maxPosition - ui.position.left;
                    }
                    if(ui.size.width < settings.dayWidth) ui.size.width = settings.dayWidth;
                    if(ui.size.width < self.minWidth) ui.size.width = self.minWidth;
                    jsPlumb.repaint(ui.helper);
                },
                stop: function (event, ui) {
                    self.moved = true;
                    self.width = self.worm.width();
                    jsPlumb.repaintEverything();
                    self.validate();
                }
            });
        } else {
            this.worm.css('cursor', 'default');
            this.editable = true;
        }
        if (typeof settings.issueWormCallback == 'function') {
            settings.issueWormCallback(self);
        }
        if (typeof self.css_classes == 'string') {
            this.worm.addClass(self.css_classes);
        }
    }

    Issue.prototype.validate = function () {
        $.ajax({
            url: settings.validateIssueUrl,
            type: 'POST',
            data: {
                issue_id: this.id,
                start: getPositionDate(this.position, this.group.gantt).format(settings.dateFormat),
                end: getPositionDate(this.position + this.width, this.group.gantt).subtract(1, 'day').format(settings.dateFormat)
            },
            dataType: 'json',
            success: function (response) {
                if (response) {
                    flash(response.type, response.html);
                } else {
                    clearFlash();
                }
            }
        });
    };

    Issue.prototype.moveFromWeekends = function (currentPosition) {
        var original = {
                position: this.position,
                width: this.worm.width(),
                start: getPositionDate(this.position, this.group.gantt),
                end: getPositionDate(this.position - settings.dayWidth + this.worm.width(), this.group.gantt)
            },
            current = {
                position: currentPosition,
                width: original.width,
                start: getPositionDate(currentPosition, this.group.gantt),
                end: getPositionDate(currentPosition - settings.dayWidth + this.worm.width(), this.group.gantt)
            };

        // cannot start on weekend
        while (!isWorkingDay(current.start)) {
            current.position += settings.dayWidth;
            current.start.add(1, 'day');
            current.end.add(1, 'day');
        }

        // cannot end on weekend
        while (!isWorkingDay(current.end)) {
            current.width -= settings.dayWidth;
            current.end.subtract(1, 'day');
        }

        // keep number of original business days
        original.businessDays = businessDays(original.start, original.end);
        current.businessDays = businessDays(current.start, current.end);

        while (original.businessDays > current.businessDays) {
            current.width += settings.dayWidth;
            current.end.add(1, 'day');
            if (isWorkingDay(current.end)) {
                current.businessDays += 1;
            }
        }
        while (original.businessDays < current.businessDays) {
            current.width -= settings.dayWidth;
            current.end.subtract(1, 'day');
            if (isWorkingDay(current.end)) {
                current.businessDays -= 1;
            }
        }

        this.worm.css({
            left: current.position,
            width: current.width
        });

        return {
            current: current,
            original: original
        }
    };

    Issue.prototype.moveRelations = function (diff, isFinal) {
        var relatedIssue, positions;
        $.each(this.relationsTo, function () {
            if(this.isStrictConnection()) {
                relatedIssue = this.from;
                relatedIssue.worm.css('left', relatedIssue.position + diff);
                if (isFinal) {
                    positions = relatedIssue.moveFromWeekends(relatedIssue.position + diff);
                    relatedIssue.moveRelations(positions.current.position - positions.original.position + (positions.current.width - positions.original.width), isFinal);
                    relatedIssue.position = positions.current.position;
                    relatedIssue.width = positions.current.width;
                    relatedIssue.moved = true
                } else {
                    relatedIssue.moveRelations(diff, isFinal)
                }
                jsPlumb.repaint(relatedIssue.worm);
            }
        });
    };

    Issue.prototype.tooltipContent = function () {
        return $('<div/>')
        .append('<h5>' + this.name + '</h5>')
        .append('<p><strong>' + settings.lang.start + ': </strong>' + formatDate(this.start) + '</p>')
        .append('<p><strong>' + settings.lang.end + ': </strong>' + formatDate(this.end) + '</p>')
        .append('<p><strong>' + settings.lang.est + ': </strong>' + (this.est ? Math.round(this.est*100)/100 : '') + '</p>')
        .append('<p><strong>' + settings.lang.completed + ': </strong>' + this.percentcompleted + '%</p>')
        .append('<p><strong>' + settings.lang.assignedTo + ': </strong>' + this.assignedto + '</p>');
    };

    Issue.prototype.connectRelations = function () {
        var that = this,
        issueFrom;
        $.each(this.relations_to, function () {
            if (issueFrom = gantt.findIssue(this.issue_from_id, 10)) {
                new IssueRelation(this.id, issueFrom, that, this.type);
            }
        });
    };

    function IssueRelation(id, from, to, type) {
        var buff;
        if (RELATION_TYPES[type].reverse) {
            type = RELATION_TYPES[type].reverse
            buff = to;
            to = from;
            from = buff;
        }
        this.id   = id;
        this.from = from;
        this.to   = to;
        this.type = type;
        from.relationsFrom.push(this);
        to.relationsTo.push(this);
        gantt.relations.push(this);
        this.paint();
    }

    IssueRelation.prototype.paint = function () {
        var self = this;
        if (this.isStrictConnection()) {
            if (this.to.connectorOut && this.from.connectorIn) {
                this.connection = jsPlumb.connect({
                    source: this.to.connectorOut,
                    target: this.from.connectorIn,
                    hoverClass: 'hover',
                    cornerRadius: 5,
                });
                this.connection.setPaintStyle({strokeStyle: RELATION_TYPES[this.type].color, lineWidth: 1, cornerRadius: 5});
            }
        } else {
            if (this.to.connectorUniversal && this.from.connectorUniversal) {
                this.connection = jsPlumb.connect({source: this.to.connectorUniversal, target: this.from.connectorUniversal});
                this.connection.setPaintStyle({dashstyle: '1 2', strokeStyle: RELATION_TYPES[this.type].color, lineWidth: 2});
            }
        }
        if (this.connection) {
            this.connection.setHoverPaintStyle({strokeStyle: '#ff0000'});
            this.connection.bind('click', function() {
                if (gantt.destroyingRelations) {
                    self.destroy()
                }
            });
        }
        if (!this.isVisible()) this.hide();
    };

    IssueRelation.prototype.isStrictConnection = function () {
        return this.type === 'follows' || this.type === 'blocks';
    };

    IssueRelation.prototype.paintStyle = function () {
        if (this.isStrictConnection()) {
            return {
                strokeStyle: RELATION_TYPES[this.type].color,
                lineWidth: 1
            };
        } else {
            return {
                dashstyle: '1 2',
                strokeStyle: RELATION_TYPES[this.type].color,
                lineWidth: 2
            };
        }
    };

    IssueRelation.prototype.hide = function () {
        if (this.connection) {
            this.connection.setVisible(false);
        }
    };

    IssueRelation.prototype.show = function () {
        if (this.connection) {
            this.connection.setVisible(true);
        }
    };

    IssueRelation.prototype.isVisible = function () {
        return !!RELATION_TYPES[this.type].visible && !this.from.isHidden && !this.to.isHidden;
    };

    IssueRelation.prototype.destroy = function () {
        gantt.destroyingRelations = false;
        if (this.connection) {
            jsPlumb.detach(this.connection);
        }
        $.ajax({
            type: 'delete',
            url: settings.relativeUrlRoot + 'relations/' + this.id + '.js',
            complete: function() {
                gantt.gantt.removeClass('new-relation');
                $('.gantt-relation').toggle();
                gantt.reload();
            }
        });
    };

    function Milestone(data, group) {
        var self = this;
        this.group = group;
        for(p in data) this[p] = data[p];
            this.position = getDatePosition(this.date, this.group.gantt);

        this.createMenuItem();
        this.menuItem.addClass('milestone-menu-item');

        if (settings.permissions.issueCreation) {
            this.createContextMenu();
            this.bindContextMenuEvents();
        }

        this.createRhombus();

        if(this.group.gantt.end < this.end) {
            this.group.gantt.addDays(countDays(this.group.gantt.end, this.date));
        }
    };

    Milestone.prototype.createMenuItem = function () {
        var name = '';
        for(var i = 0; i < this.level; i++) name += '&nbsp;&nbsp;&nbsp;&nbsp;';
            name += this.name;
        this.menuItem = $('<tr/>')
        .append(
            $('<td/>').append(
                $('<a/>').html(name)
                    .attr('href', this.link || 'javascript:void(0);')
                    .attr('title', this.name)
            ).attr('colspan', gantt.issueColumns.length + 1)
        ).appendTo(this.group.issueMenu);
        if(typeof this.css_classes == 'string') {
            this.menuItem.addClass(this.css_classes);
        }
    };

    Milestone.prototype.createRhombus = function () {
        var self = this;
        this.rhombus = $('<div/>')
        .addClass('milestone-worm')
        .appendTo(this.group.gantt.gridBody)
        .css('left', this.position)
        .css('top', this.rowIndex * settings.rowHeight)
        .draggable({
            axis: 'x',
            grid:[settings.dayWidth, settings.rowHeight],
            containment: 'parent',
            stop: function (event, ui) {
                if(ui.position.left != ui.originalPosition.left) {
                    self.moved = true;
                    self.position = ui.position.left;
                }
            }
        });
    };

    Milestone.prototype.createContextMenu = function () {
        this.contextMenu = $('<ul/>').addClass('gantt-context-menu');
        var self = this;

        $('<a/>').attr('href', 'javascript:void(0)').html(l(this, 'newMilestoneIssue')).click(function () {
            self.group.gantt.newMilestoneIssue(self.id);
        }).appendTo($('<li/>').appendTo(this.contextMenu));
    };

    // inheritance from issue
    Milestone.prototype.bindContextMenuEvents = Issue.prototype.bindContextMenuEvents;

    function countDays(start, end) {
        if(start && end) {
            return Math.round((end - start)/(3600000*24));
        } else {
            return 0;
        }
    }


    function isWeekend(d) {
        return d.day() === 6 || d.day() === 0;
    }

    function isWorkingDay(d) {
        var isHoliday = false;
        if (isWeekend(d)) {
            return false;
        }
        $.each(settings.holidays, function () {
            if (this.isRepeating ? (this.date.date() === d.date() && this.date.month() === d.month()) : this.date.isSame(d)) {
                isHoliday = true;
                return false;
            }
        });
        return !isHoliday;
    }

    function getDatePosition(d, gantt) {
        if(d) {
            return (countDays(gantt.start, d))*settings.dayWidth;
        } else {
            return null;
        }
    }

    function getPositionDate(p, gantt) {
        return gantt.start.clone().add(Math.round(p)/settings.dayWidth, 'days');
    }

    function businessDays(start, end) {
        var x = start.clone(),
            businessDays = 1;

        if (start > end) {
            return 0;
        }

        while (x < end) {
            if (isWorkingDay(x)) {
                businessDays += 1;
            }
            x.add(1, 'day');
        }

        return businessDays;
    }

    function findGroup(users, id) {
        for(var i = 0; i < users.length; i++) {
            if(users[i].data.id == id) return users[i];
        }
    }

    function l(object, key) {
        switch(object.constructor) {
            case Issue:
                return object.group.gantt.settings.lang[key];
                break;
            case Milestone:
                return object.group.gantt.settings.lang[key];
                break;
        }
    }

    function formatDate(d) {
        return d.format(settings.humanDateFormat);
    }

    function flash(klass, message) {
        clearFlash();
        $('<div/>').addClass('flash').addClass(klass).append(
            $('<span/>').html(message)
            ).prependTo($('#content'));
    }

    function clearFlash() {
        $('#content div.flash').remove();
    }

    function epOptions() {
        return {
            paintStyle: {radius: 0, fillStyle: '#ffffff'},
            connectorStyle: {strokeStyle: '#1111aa', lineWidth: 0.5},
            endpoint: 'Blank',
            maxConnections: 1000,
            connector: 'Flowchart',
            reAttachConnections: false,
            connectorOverlays:[
                ["Arrow", {foldback: 1, width: 7, length: 7, id: "arrow", location: 0}],
                ["Arrow", {foldback: 1, width: 7, length: 7, id: "arrow", location: 1}],
            ]
        };
    }

    if(typeof patchEasyGantt == 'function') {
        patchEasyGantt.call({
            EasyGantt: EasyGantt,
            Project: Project,
            Group: Group,
            Issue: Issue,
            IssueRelation: IssueRelation,
            countDays: countDays,
            getDatePosition: getDatePosition,
            getPositionDate: getPositionDate,
            isWeekend: isWeekend,
            isWorkingDay: isWorkingDay,
            findGroup: findGroup,
            formatDate: formatDate
        });
    }

})(jQuery);
