(function($) {

    var settings = {
        dayWidth: 24,
        rowHeight: 22,
        loadUrl: '/user_allocation_gantt/data.json',
        recalculateUrl: '/user_allocation_gantt/recalculate.json',
        saveIssuesUrl: '/user_allocation_gantt/save_issues',
        splitIssueUrl: '/user_allocation_gantt/split_issue.json',
        loadParams: function() {
            return {
                users: $('#filters_users').val() || '',
                period_type: $('input[name="filters[period_type]"]:checked').val(),
                period: $('#filters_period').val(),
                from: $('#period_from').val(),
                to: $('#period_to').val()
            };
        },
        dateFormat: 'YYYY-MM-DD',
        humanDateFormat: 'D. M. YYYY',
        saveCallback: function(resalloc, response) {
            resalloc.flash(response.html, response.type);
        },
        todayLine: true
    }

    $.fn.resalloc = function(options, methodParams) {
        //init
        var ra;
        if (typeof options == 'object') {
            settings = $.extend(settings, options);
            ra = new Resalloc($(this), settings);
            $.data(this[0], 'resalloc', ra);
        }
        //method calling
        else if (typeof options == 'string') {
            ra = $.data(this[0], 'resalloc');
            switch (options) {
                case 'applyFilters':
                    ra.clean();
                    ra.loadData(this.settings.loadUrl, this.settings.loadParams);
                    break;
                case 'saveIssues':
                    ra.saveIssues();
                    break;
                case 'recalculate':
                    ra.recalculate();
                    break;
                case 'splitIssue':
                    ra.toggleSplitMode(methodParams);
                    break;
            }
        }
    };

    function Resalloc(container, settings) {
        var resalloc = this, h;
        this.container = container;
        this.settings = settings;
        h = window.innerHeight - this.container[0].offsetTop - 60;
        this.ra = $('<div/>')
                .appendTo(this.container)
                .addClass('resalloc')
                .css('height', Math.max(h, 400));
        this.userListContainer = $('<div/>').addClass('user-list-container').appendTo(this.ra);
        ;
        this.userList = $('<ul/>').addClass('user-list').appendTo(this.userListContainer);

        var gc = $('<div/>').addClass('grid-container').appendTo(this.ra);
        this.gridHeaderContainer = $('<div/>').addClass('grid-header-container').appendTo(gc);
        this.gridHeader = $('<div/>').addClass('grid-header').appendTo(this.gridHeaderContainer);
        this.gridBodyContainer = $('<div/>').appendTo(gc).addClass('grid-body-container');
        this.gridBody = $('<div/>').addClass('grid-body').appendTo(this.gridBodyContainer);
        this.gridBodyContainer.css('height', this.ra.height() - 2 * settings.rowHeight);
        this.gridBodyContainer.scroll(function(e) {
            resalloc.afterScroll(this, e);
        });

        this.loadData(this.settings.loadUrl, this.settings.loadParams);
        this.users = [];
    }

    Resalloc.prototype.scrollToToday = function() {
        this.gridBodyContainer[0].scrollLeft = getDatePosition(moment(), this);
        this.gridBodyContainer.scroll();
    };

    Resalloc.prototype.afterScroll = function(el, e) {
        $(this.gridHeaderContainer)[0].scrollLeft = el.scrollLeft;
        $(this.userListContainer)[0].scrollTop = el.scrollTop;
    };

    Resalloc.prototype.createCalendar = function() {

        var d = this.start.clone();
        var mc;
        var monthDiv;
        var daysDiv;

        var width = 2 + (1 + countDays(this.start, this.end)) * this.settings.dayWidth;
        this.gridHeader.css('width', width);
        this.gridBody.css('width', width);

        while (d.isBefore(this.end) || d.isSame(this.end)) {
            if (!mc || d.date() == 1) {
                mc = $('<div/>').addClass('month-container').appendTo(this.gridHeader);
                var text = d.year() + '/' + (d.month() + 1);
                monthDiv = $('<div/>').addClass('month').append(text).attr('title', text).appendTo(mc);
                dayDiv = $('<div/>').addClass('days').appendTo(mc);
            }
            var ds = $('<span/>').append(d.date()).appendTo(dayDiv);
            if (d.day() === 6 || d.day() === 0)
                ds.addClass('weekend');
            d.add('days', 1);
            monthDiv.css('width', dayDiv.children().length * settings.dayWidth - 9);
        }

        if (this.settings.todayLine)
            this.createTodayLine();

        var bgPos = getDatePosition(this.start.clone().day(8), this);
        this.gridBody.css('background-position-x', bgPos).css('background-position', bgPos + 'px 0');
    }

    Resalloc.prototype.createTodayLine = function() {
        $('<div/>').html('&nbsp;').addClass('todayLine').css('left', getDatePosition(moment(), this) + this.settings.dayWidth / 2).appendTo(this.gridBody);
    }

    Resalloc.prototype.clean = function() {
        this.gridHeader.empty();
        this.gridBody.empty();
        this.userList.empty();

        this.users = [];
        this.start = null;
        this.end = null;
        this.data = null;
    }

    Resalloc.prototype.loading = function() {
        // if (this.loadDiv) {
        //  this.loadDiv.remove();
        //  this.loadDiv = null;
        // }
        // else {
        //  this.loadDiv = $('<div/>').addClass('loader').html('&nbsp;').appendTo(this.gridBody);
        //  this.loadDiv.css('top', Math.round(parseFloat(this.ra.css('height')) / 2) - 16);
        //  this.loadDiv.css('left', Math.round(parseFloat(this.ra[0].offsetWidth) / 2) - 16 - this.userList[0].offsetWidth);
        // }
    }

    Resalloc.prototype.loadData = function(url, params) {
        this.loading();
        var ra = this;
        $.getJSON(url, typeof params == 'function' ? params() : params, function(data) {
            if (data.start)
                ra.start = moment(data.start);
            if (data.end)
                ra.end = moment(data.end);
            ra.createCalendar();
            ra.createRows(data);
            ra.scrollToToday();
            ra.loading();
        });
    }

    Resalloc.prototype.createRows = function(data) {
        if (data.unassigned)
            this.unassigned = new Unassigned(this, data.unassigned);
        if (typeof data.users == 'object') {
            var rowCount = this.unassigned ? this.unassigned.issues.length + 1 : 0;
            for (var i = 0; i < data.users.length; i++) {
                this.users.push(new User(data.users[i], i, this));
                rowCount += 1 + this.users[this.users.length - 1].issues.length + this.users[this.users.length - 1].projects.length;
            }
        }
        window.users = this.users;
        this.gridBody.css('height', this.settings.rowHeight * rowCount);
        this.userList.css('height', this.settings.rowHeight * rowCount + 100);
        if (this.ra.height() > (rowCount + 3) * this.settings.rowHeight) {
            this.setHeight((rowCount + 3) * this.settings.rowHeight);
        }
    }

    Resalloc.prototype.changedUsers = function(changedUsers) {
        changedUsers = [];
        for (var i = 0; i < this.users.length; i++) {
            var changedIssues = this.users[i].changedIssuesData();
            if (((function(obj) {
                for (var i in obj)
                    return true;
            })(changedIssues)) || this.users[i].ignoredIssueIds.length > 0) {
                changedUsers.push({id: this.users[i].data.id, issues: changedIssues, ignoredIssueIds: this.users[i].ignoredIssueIds});
            }
        }
        return changedUsers;
    };

    Resalloc.prototype.warnOverallocation = function(changedUsers) {
        var sum, names = [];
        $.each(changedUsers, function() {
            $.each(this.issues, function() {
                sum = 0;
                if (this.customAllocation) {
                    $.each(this.customAllocation, function(key, val) {
                        sum += val;
                    });
                    if (this.est < sum) {
                        names.push(this.name);
                    }
                }
            });
        });

        if (names.length > 0) {
            this.flash(names.join(', ') + ' - ' + settings.lang.overallocation, 'warning');
        }
    };

    Resalloc.prototype.recalculate = function(changedUsers) {
        var self = this;
        this.loading();

        var changedUsers = changedUsers || this.changedUsers();
        this.warnOverallocation(changedUsers);

        var params = typeof this.settings.loadParams == 'function' ? this.settings.loadParams() : this.settings.loadParams;

        $.ajax({
            url: this.settings.recalculateUrl,
            type: "POST",
            dataType: "json",
            data: {
                changed_users: JSON.stringify(changedUsers),
                period_type: params.period_type,
                period: params.period,
                from: params.from,
                to: params.to
            },
            success: function(data) {
                for (var i = 0; i < data.users.length; i++) {
                    var u = findUser(self.users, data.users[i].id)
                    u.userAllocDiv.empty();

                    for (var j = 0; j < data.users[i].allocations.length; j++) {
                        var alloc = data.users[i].allocations[j];
                        var allocSpan = $('<span/>').appendTo(u.userAllocDiv).addClass(alloc.over ? 'over' : '').attr('title', alloc.activity_name);
                        if (alloc.hours > 0) {
                            allocSpan.html(formatHours(alloc.hours, true));
                        } else if (alloc.activity_name) {
                            allocSpan.html(alloc.activity_name[0]);
                        } else {
                            allocSpan.html('&nbsp;');
                        }
                        if (alloc.color_schema)
                            allocSpan.addClass(alloc.color_schema);
                    }

                    for (var j = 0; j < data.users[i].entities.length; j++) {
                        var entity = data.users[i].entities[j];
                        if (entity.type == 'issue') {
                            var issue = findIssue(u.issues, entity.id);
                            if (issue) {
                                issue.start = moment(entity.start);
                                issue.est = entity.est;
                                issue.worm.css('width', '');
                                issue.worm.css('left', getDatePosition(issue.start, self));
                                issue.worm.css('top', issue.ra.settings.rowHeight * issue.rowIndex);
                                issue.worm.children('span, input').remove();
                                issue.allocations = [];
                                issue.customAllocation = new CustomAllocation(issue);
                                for (var k = 0; k < entity.allocations.length; k++) {
                                    var al = $('<span/>').html(formatHours(entity.allocations[k].hours)).appendTo(issue.worm);
                                    if (!entity.allocations[k].hours || entity.allocations[k].hours === 0) {
                                        al.addClass('no-hours');
                                    }
                                    if (entity.allocations[k].over) {
                                        al.addClass('over');
                                    }
                                    if (entity.allocations[k].custom) {
                                        al.addClass('custom');
                                        issue.customAllocation.allocate(issue.start.clone().add('days', k), entity.allocations[k].hours)
                                    } else {
                                        issue.allocations.push(entity.allocations[k]);
                                    }
                                }
                                issue.createMenuItem();
                            }
                        }
                    }
                }
                self.loading();
            }
        });
    }

    Resalloc.prototype.expandIfNeeded = function(x) {
        var spaceLeft = parseFloat(this.gridBody.css('width')) - x;
        if (spaceLeft < this.settings.dayWidth * 2) {
            this.addDays(7);
        }
    }

    Resalloc.prototype.addDays = function(n) {
        for (var i = 0; i < n; i++)
            this.addDay();
    }

    Resalloc.prototype.addDay = function() {
        var newEnd = this.end.clone().add('days', 1);
        var daysDiv, monthDiv;
        if (newEnd.month() == this.end.month()) {
            monthDiv = $('div.month:last');
            daysDiv = $('div.days:last', this.gridHeader);
        }
        else {
            mc = $('<div/>').addClass('month-container').appendTo(this.gridHeader);
            monthDiv = $('<div/>').addClass('month').append(newEnd.year() + '/' + (newEnd.month() + 1)).appendTo(mc).css('width', 0);
            daysDiv = $('<div/>').addClass('days').appendTo(mc);
        }

        this.gridHeader.css('width', parseFloat(this.gridHeader.css('width')) + this.settings.dayWidth);
        this.gridBody.css('width', this.gridHeader.css('width'));

        var ds = $('<span/>').append(newEnd.date()).appendTo(daysDiv);
        if (newEnd.day() === 6 || newEnd.day() === 0)
            ds.addClass('weekend');
        monthDiv.css.width(daysDiv.children().length * settings.dayWidth - 8);

        this.end = newEnd;
    }

    Resalloc.prototype.saveIssues = function() {
        var self = this;
        this.loading();
        var changedIssues = {};
        for (var i = 0; i < this.users.length; i++) {
            for (var j = 0; j < this.users[i].issues.length; j++) {
                if (this.users[i].issues[j].changed) {
                    this.users[i].issues[j].originalstart = users[i].issues[j].start;
                    this.users[i].issues[j].duedate = users[i].issues[j].end;
                    this.users[i].issues[j].worm.qtip('option', 'content.text', this.users[i].issues[j].tooltipContent());
                    changedIssues[this.users[i].issues[j].id.toString()] = {
                        assigned_to_id: this.users[i].data.id,
                        start: users[i].issues[j].start.format(this.settings.dateFormat),
                        end: this.users[i].issues[j].end.format(this.settings.dateFormat),
                        customAllocation: this.users[i].issues[j].customAllocation.data
                    };
                }
            }
        }
        if (this.unassigned && this.unassigned.issues.length > 0) {
            for (var i = 0; i < this.unassigned.issues.length; i++) {
                var issue = this.unassigned.issues[i];
                if (issue.changed)
                    changedIssues[issue.id.toString()] = {
                        assigned_to_id: ''
                    }
            }
        }
        $.post(this.settings.saveIssuesUrl, {issues: changedIssues}, function(response) {
            self.settings.saveCallback(self, response);
            $('div.resalloc li.changed').removeClass('changed').attr('title', '');
            self.loading();
        });
    }

    Resalloc.prototype.toggleSplitMode = function(options) {
        this.splitButton = $(options.button);
        this.splitHelpSelector = options.helpSelector;
        if (this.splitMode)
            this.disableSplitMode($(options.button), $(options.helpSelector));
        else
            this.enableSplitMode($(options.button), $(options.helpSelector));
    };

    Resalloc.prototype.enableSplitMode = function(button, help) {
        button.addClass('pressed');
        help.fadeIn();
        this.splitMode = true;
    };

    Resalloc.prototype.disableSplitMode = function(button, help) {
        (button || this.splitButton).removeClass('pressed');
        (help || $(this.splitHelpSelector)).fadeOut();
        this.splitMode = false;
    };

    Resalloc.prototype.setHeight = function(h) {
        h += 50;
        this.ra.css('height', h);
        this.userListContainer.css('height', this.ra.height() - 2 * this.settings.rowHeight);
        this.gridBodyContainer.css('height', this.ra.height() - 2 * this.settings.rowHeight);
    };

    Resalloc.prototype.flash = function(messages, type) {
        $('div.resalloc-flash').remove();
        var fl = $('<div/>')
                .addClass('flash resalloc-flash')
                .addClass(type)
                .append($('<span/>').html(messages)).insertBefore(this.container);

        $('<a/>')
                .addClass('icon icon-close')
                .prependTo(fl)
                .click(function() {
            fl.fadeOut(500, function() {
                fl.remove();
            })
        });
    };


    function countDays(start, end) {
        return end.diff(start, 'days');
    }

    function getDatePosition(d, ra) {
        return (countDays(ra.start, d)) * ra.settings.dayWidth;
    }

    function getPositionDate(p, ra) {
        var days = Math.round(p / ra.settings.dayWidth);
        return ra.start.clone().add('days', days);
    }

    function findUser(users, id) {
        for (var i = 0; i < users.length; i++) {
            if (users[i].data.id == id)
                return users[i];
        }
    }

    function findIssue(issues, id) {
        for (var i = 0; i < issues.length; i++) {
            if (issues[i].id == id)
                return issues[i];
        }
    }

    function formatHours(hours, smallDecimal) {
        var decimal, formatted;

        hours = parseFloat(hours);

        if (smallDecimal) {
            formatted = Math.floor(hours).toString();
            decimal = hours - Math.floor(hours, 10);
            if (decimal > 0) {
                formatted += '.<span class="decimal">' + Math.round(decimal * 10).toString() + '</span>';
            }
            return formatted;
        } else {
            return (Math.round(hours * 10) / 10).toString();
        }
    }

    function User(userData, rowIndex, ra) {
        this.data = userData;
        this.ra = ra;
        this.rowIndex = this.defaultRowIndex();
        for (var i = 0; i < this.ra.users.length; i++) {
            this.rowIndex += 1 + this.ra.users[i].issues.length + this.ra.users[i].projects.length;
        }
        this.projects = [];
        this.issues = [];
        this.ignoredIssueIds = [];
        this.createMenuItem();
        this.createAllocation();
        this.createEntities();
    }

    User.prototype.createEntities = function() {
        this.issueMenu = $('<ul/>').addClass('task-list').insertAfter(this.menuItem);
        if (this.data.entities && this.data.entities.length > 0) {
            for (var i = 0; i < this.data.entities.length; i++) {
                var entityData = this.data.entities[i];
                if (entityData.type == 'project') {
                    this.parseProjectData(i);
                    this.projects.push(new Project(this, entityData));
                } else {
                    this.parseIssueData(i);
                    this.issues.push(new Issue(this, entityData));
                }
                ;
            }
        }
        this.dropArea.css('height', this.ra.settings.rowHeight * (this.issues.length + this.projects.length + 1) - 1);
    }

    User.prototype.defaultRowIndex = function() {
        return this.ra.unassigned ? this.ra.unassigned.issues.length + 1 : 0;
    }

    User.prototype.createMenuItem = function() {
        this.menuItem = $('<li/>').append($('<a/>').attr('href', this.data.url).html(this.data.name)).appendTo(this.ra.userList);
        var currentUser = this;
        if (this.data.entities.length == 0) {
            this.menuItem.addClass('no-issues');
        }
    }

    User.prototype.createAllocation = function() {
        var self = this;

        this.userAllocDiv = $('<div/>').appendTo(this.ra.gridBody).addClass('user-allocation').css('top', this.rowIndex * this.ra.settings.rowHeight);
        for (var i = 0; i < this.data.allocations.length; i++) {
            var alloc = this.data.allocations[i];
            var allocSpan = $('<span/>').appendTo(this.userAllocDiv).addClass(alloc.over ? 'over' : '').attr('title', alloc.activity_name);
            if (alloc.activity_name) {
                allocSpan.html(alloc.activity_short_name || alloc.activity_name[0]);
            } else if (typeof alloc.hours !== 'undefined') {
                allocSpan.html(formatHours(alloc.hours, true));
            } else {
                allocSpan.html('&nbsp;');
            }
            if (alloc.color_schema) {
                allocSpan.addClass(alloc.color_schema)
            }
            ;
        }
        ;

        this.dropArea = $('<div/>')
                .addClass('drop-area')
                .css('top', this.userAllocDiv.css('top'))
                .css('height', this.ra.settings.rowHeight - 1)
                .insertAfter(this.userAllocDiv)
                .droppable({
            activeClass: 'dropping',
            hoverClass: 'hover',
            drop: function(event, ui) {
                var issue = ui.draggable.data('issue');

                var newLeft = parseFloat(ui.draggable.css('left'));
                var newStart = getPositionDate(newLeft, self.ra);

                if (!issue.start.isSame(newStart, 'days')) {
                    issue.start = newStart;
                    issue.end = getPositionDate(newLeft + parseFloat(ui.draggable.css('width')), self.ra).subtract('days', 1);
                    issue.setChanged();
                    issue.deletePastCustomAllocations();
                }

                if (issue.user != self) {
                    issue.assignTo(self);
                }
                self.recalculate();
            }
        });
    }

    User.prototype.parseProjectData = function(i) {
        this.data.entities[i].rowIndex = 1 + this.rowIndex + i;
    };

    User.prototype.parseIssueData = function(i) {
        this.data.entities[i].rowIndex = 1 + this.rowIndex + i;
        this.data.entities[i].start = moment(this.data.entities[i].start);
        this.data.entities[i].end = moment(this.data.entities[i].end);
        this.data.entities[i].startdate = moment(this.data.entities[i].startdate);
        this.data.entities[i].duedate = moment(this.data.entities[i].duedate);
        this.data.entities[i].originalstart = moment(this.data.entities[i].originalstart);
    };

    User.prototype.changedIssuesData = function() {
        var changedIssues = {}, issue, i;
        for (i = 0; i < this.issues.length; i += 1) {
            issue = this.issues[i];
            changedIssues[issue.id.toString()] = {
                name: issue.name,
                est: issue.est,
                start: issue.start.format(this.ra.settings.dateFormat),
                end: issue.end.format(this.ra.settings.dateFormat),
                customAllocation: issue.customAllocation.data,
                resized: !!issue.resized
            };
        }
        return changedIssues;
    }

    User.prototype.recalculate = function(assignedIssue) {
        var changedIssues = this.changedIssuesData();
        var any = false;
        for (var i in changedIssues)
            any = true;
        if (any) {
            this.ra.recalculate([{id: this.data.id, issues: changedIssues, ignoredIssueIds: this.ignoredIssueIds}]);
        } else {
            this.ra.recalculate([{id: this.data.id, issues: {}, ignoredIssueIds: this.ignoredIssueIds}]);
        }
    }

    function Project(user, data) {
        for (p in data) {
            this[p] = data[p];
        }
        this.user = user;
        this.createMenuItem();
    }

    Project.prototype.createMenuItem = function() {
        this.menuItem = $('<li>')
                .addClass('project')
                .append($('<a/>')
                .attr('title', this.name)
                .html(this.name)
                .attr('href', this.href ? this.href : 'javascript:void(0);'))
                .appendTo(this.user.issueMenu);
    }

    function Issue(user, data) {
        for (p in data) {
            this[p] = data[p];
        }
        this.customAllocation = new CustomAllocation(this);
        this.unassigned = user.constructor == Unassigned;
        this.user = user;
        this.ra = this.user.ra;
        this.createMenuItem();
        this.createWorm();
    }

    Issue.prototype.createMenuItem = function() {
        var self = this;
        if (this.menuItem) {
            this.menuItem.empty();
        } else{
            this.menuItem = $('<li>').appendTo(this.user.issueMenu);
        }
        this.menuItem
                .append($('<a/>')
                .attr('title', this.name)
                .html(this.name)
                .attr('href', this.href ? this.href : 'javascript:void(0);')
                .click(function() {
            self.dialogEdit();
            return false;
        })
                )
                .addClass(this.css_classes);
        if (this.project) {
            this.menuItem.append($('<a/>').attr('title', this.project).attr('href', this.projecthref).html(this.project));
        }
        this.menuItem.append($('<span/>').html(this.status).addClass('status-span'));
        this.estSpan = $('<span/>').html('(' + this.est + ')').appendTo(this.menuItem);
        if (!self.unassigned) {
            this.estLink = $('<a/>').appendTo(this.menuItem).click(function() {
                self.editEstimatedHours();
            }).attr('title', settings.lang.editEst);
            this.estSpan.appendTo(this.estLink);
        }
    };

    Issue.prototype.dialogEdit = function() {
        var self = this,
                editDialog = $('#resalloc-edit-dialog');
        if (editDialog.length > 0) {
            editDialog.remove();
        }
        editDialog = $('<div/>')
                .attr('id', 'resalloc-edit-dialog')
                .appendTo('body');

        $.get(self.href + '/edit?for_dialog=1', {}, function(data) {
            editDialog.html(data);
            var dialogButtons = {};
            dialogButtons[self.ra.settings.lang.save] = function() {
                var f = $('#issue-form', editDialog);
                $.ajax({
                    type: 'post',
                    url: f.attr('action') + '?for_dialog=1',
                    data: f.serialize(),
                    complete: function(jqXHR) {
                        if (jqXHR.status === 422) {
                            editDialog.html(jqXHR.responseText);
                        } else {
                            window.location.reload();
                        }
                    }
                });
            };
            dialogButtons[self.ra.settings.lang.cancel] = function() {
                editDialog.dialog('close');
            }
            editDialog.dialog({
                width: 900,
                modal: true,
                buttons: dialogButtons
            });
        });
    };

    Issue.prototype.createWorm = function() {
        var self = this;
        this.worm = $('<div/>').addClass('worm').appendTo(this.ra.gridBody);
        if (this.allocations) {
            for (var i = 0; i < this.allocations.length; i++) {
                var al = $('<span/>').html(formatHours(this.allocations[i].hours)).appendTo(this.worm);
                if (!this.allocations[i].hours || this.allocations[i].hours === 0) {
                    al.addClass('no-hours');
                }
                if (this.allocations[i].over) {
                    al.addClass('over');
                }
                if (this.allocations[i].custom) {
                    al.addClass('custom');
                    this.customAllocation.allocate(this.start.clone().add('days', i), this.allocations[i].hours);
                }
            }
        }
        this.worm.css('left', getDatePosition(this.start, this.ra));
        this.worm.css('top', this.rowIndex * this.ra.settings.rowHeight);
        if (typeof this.wormtitle == 'string')
            this.worm.attr('title', this.wormtitle);
        if (this.is_planned) {
            this.worm.css('background-size', '100% 100%').addClass('planned');
        }
        if (this.readonly) {
            this.worm.addClass('readonly');
            return this;
        }
        if (!this.originalstart || !this.originalstart.isSame(this.start, 'day')) {
            if (!this.originalstart.isBefore(this.ra.start)) {
                this.setChanged();
            }
        }
        ;
        if (!this.unassigned)
            this.end = getPositionDate(this.worm.position().left + parseFloat(this.worm.css('width')), this.ra).subtract('days', 1);

        this.worm.qtip({
            content: this.tooltipContent(),
            position: {
                target: 'mouse',
                adjust: {
                    x: 10,
                    y: 10,
                    mouse: false,
                    screen: true
                }
            },
            show: {
                delay: 100
            },
            hide: {
                event: 'mouseleave',
                distance: 15
            }
        });

        if (this.spenttime) {
            // this.worm.css('background-size', '' + this.spenttime * 100 / this.est + '% 100%');
            if (this.spenttime > this.est) {
                this.worm.css('background-size', '100% 100%');
                this.worm.addClass('overshot');
            }
        }

        if (settings.readonly) {
            this.worm.css('cursor', 'default');
            return;
        }
        this.worm.draggable({
            grid: [24, 22],
            containment: 'parent',
            revert: 'invalid',
            start: function() {
                $(this).qtip('hide').qtip('disable');
            },
            stop: function() {
                $(this).qtip('enable');
            }
        })
        this.worm.resizable({
            grid: [24, 22],
            minWidth: 20,
            handles: 'w,e',
            containment: 'parent',
            start: function() {
                $(this).qtip('hide').qtip('disable');
                $('span', this).remove();
            },
            resize: function(event, ui) {
                if (ui.size.width < settings.dayWidth * $('span', this).length) {
                    $(this).children('span:last').remove();
                }
            },
            stop: function(event, ui) {
                var $this = $(this);
                $this.qtip('enable');
                self.start = getPositionDate(ui.position.left, self.ra);
                self.end = getPositionDate(ui.position.left + ui.size.width, self.ra).subtract('days', 1);
                self.setChanged();
                self.setResized();
                self.deletePastCustomAllocations();
                self.user.recalculate();
            }
        })
                .click(function(event) {
            if (self.user.constructor != Unassigned)
                return self.edit();
        })
                .click(function(event) {
            if (self.ra.splitMode && self.user.constructor == Unassigned) {
                var pos = event.pageX - self.ra.gridBody.offset().left;
                pos = Math.round(parseFloat(pos) / settings.dayWidth) * settings.dayWidth;
                self.split(getPositionDate(pos, self.ra));
                self.ra.disableSplitMode();
            }
        });

        if (this.unassigned) {
            this.worm.css('width', getDatePosition(this.end, this.ra) - getDatePosition(this.start, this.ra) + this.ra.settings.dayWidth).addClass('unassigned');
        } else {
        }

        this.worm.data('issue', this);
    }

    Issue.prototype.tooltipContent = function() {
        var c = $('<div/>').append('<h5>' + this.name + '</h5>');
        if (this.activity)
            c.append('<p><strong>' + settings.lang.activity + ': </strong>' + this.activity + '</p>');
        if (this.est)
            c.append('<p><strong>' + settings.lang.est + ': </strong>' + this.est + ' h</p>');
        if (this.spenttime) {
            var st = $('<p><strong>' + settings.lang.spenttime + ': </strong>' + this.spenttime + ' h</p>').appendTo(c);
            if (this.spenttime > this.est)
                st.css('color', 'red');
        }
        if (this.hoursleft)
            c.append('<p><strong>' + settings.lang.hoursleft + ': </strong>' + this.hoursleft + ' h</p>');
        if (this.originalstart)
            c.append('<p><strong>' + settings.lang.startdate + ': </strong>' + this.originalstart.format(settings.humanDateFormat) + '</p>');
        if (this.duedate)
            c.append('<p><strong>' + settings.lang.duedate + ': </strong>' + this.duedate.format(settings.humanDateFormat) + '</p>');
        if (this.percentcompleted)
            c.append('<p><strong>' + settings.lang.percentcompleted + ': </strong>' + this.percentcompleted + '</p>');
        if (this.author)
            c.append('<p><strong>' + settings.lang.author + ': </strong>' + this.author + '</p>');
        if (this.user.constructor == User)
            c.append('<p><strong>' + settings.lang.assignedto + ': </strong>' + this.user.data.name + '</p>');
        if (this.id)
            c.append('<p><strong>' + settings.lang.issueid + ': </strong>' + this.id + '</p>');

        return c;
    };

    Issue.prototype.editEstimatedHours = function() {
        if (newEst = prompt(this.ra.settings.lang.est, this.est)) {
            this.updateEstimatedHours(newEst);
        }
    };

    Issue.prototype.updateEstimatedHours = function(est) {
        var self = this;
        $.ajax({
            url: '/issues/' + this.id + '.json',
            type: 'PUT',
            data: {
                issue: {
                    estimated_hours: est
                }
            },
            complete: function(xhr) {
                if (xhr.status > 300) {
                    data = $.parseJSON(xhr.responseText);
                    self.ra.flash(data.errors.join('\n'), 'error');
                } else {
                    self.ra.flash(self.ra.settings.lang.successfulUpdate, 'notice');
                    self.setChanged();
                    self.user.recalculate();
                }
            }
        });
    };

    Issue.prototype.assignTo = function(user) {
        if (!user || user == this.user)
            return;
        this.ra.loading();

        this.menuItem.appendTo(user.issueMenu);
        var rh = this.ra.settings.rowHeight;

        var issueIndex = this.user.issues.indexOf(this);
        var userIndexFrom = this.ra.users.indexOf(this.user);
        var userIndexTo = this.ra.users.indexOf(user);
        this.customAllocation.deleteAll();

        if (userIndexFrom < userIndexTo) {
            for (var i = issueIndex + 1; i < this.user.issues.length; i++)
                this.user.issues[i].worm.css('top', rh * --this.user.issues[i].rowIndex);
            this.user.dropArea.css('height', this.user.dropArea.height() - rh);
            for (var i = userIndexFrom + 1; i <= userIndexTo; i++) {
                var user = this.ra.users[i];
                user.dropArea.css('top', user.dropArea.position().top - rh);
                user.userAllocDiv.css('top', user.userAllocDiv.position().top - rh);
                user.rowIndex--;
                for (var j = 0; j < user.issues.length; j++) {
                    var issue = user.issues[j];
                    issue.worm.css('top', issue.worm.position().top - rh);
                    issue.rowIndex--;
                }
            }
            var finalUser = this.ra.users[userIndexTo] || this.ra.unassigned;
            this.rowIndex = finalUser.rowIndex + finalUser.issues.length + 1;
        } else {
            for (var i = issueIndex; i >= 0; i--)
                this.user.issues[i].worm.css('top', rh * ++this.user.issues[i].rowIndex);
            this.user.dropArea.css('height', this.user.dropArea.height() - rh).css('top', this.user.dropArea.position().top + rh);
            this.user.userAllocDiv.css('top', this.user.userAllocDiv.position().top + rh)
            this.user.rowIndex++;
            for (var i = userIndexFrom - 1; i > userIndexTo; i--) {
                var u = this.ra.users[i] || this.ra.unassigned;
                u.dropArea.css('top', u.dropArea.position().top + rh);
                u.userAllocDiv.css('top', u.userAllocDiv.position().top + rh);
                u.rowIndex++;
                for (var j = 0; j < u.issues.length; j++) {
                    var issue = u.issues[j];
                    issue.worm.css('top', issue.worm.position().top + rh);
                    issue.rowIndex++;
                }
            }
            var finalUser = this.ra.users[userIndexTo] || this.ra.unassigned;
            this.rowIndex = finalUser.rowIndex + finalUser.issues.length + 1;
            finalUser.dropArea.css('height', rh + finalUser.dropArea.height());
        }

        this.worm.css('top', this.rowIndex * rh);
        $('span', this.worm).remove();

        var i = this.user.issues.indexOf(this);
        if (i >= 0)
            this.user.issues.splice(i, 1);
        var oldUser = this.user;
        this.user = user;
        this.setChanged();
        this.user.issues.push(this);

        if (!oldUser.ignoredIssueIds.indexOf(this.id) >= 0) {
            oldUser.ignoredIssueIds.push(this.id);
        }

        if ((i = this.user.ignoredIssueIds.indexOf(this.id)) >= 0) {
            this.user.ignoredIssueIds.splice(i, 1);
        }

        this.user.dropArea.css('height', rh * (this.user.issues.length + 1));

        if (this.user.constructor == Unassigned) {
            this.worm.css('width', 10);
        } else {
            this.worm.css('width', 'auto');
        }

        this.ra.loading();
        oldUser.recalculate();
    }

    Issue.prototype.edit = function() {
        var self = this;
        if (this.editMode)
            return false;
        this.doneEditingAll();
        this.editMode = true;
        this.worm.children('span').each(function() {
            $(this).replaceWith($('<input/>')
                    .attr('type', 'text')
                    .addClass('custom-allocation')
                    .val($(this).text())
                    .keyup(function() {
                var input = $(this),
                        date = getPositionDate(self.worm.position().left + input.position().left, self.ra),
                        hours = parseFloat(input.val());

                do {
                    self.customAllocation.allocate(date, hours);
                    date.add(1, 'day');
                    input = input.next();
                } while (input && (hours = parseFloat(input.val())) === 0);

            })
                    );
        });

        $(document).one('click', function() {
            self.doneEditing();
        });
        return false;
    };

    Issue.prototype.doneEditing = function() {
        if (!this.editMode)
            return;
        this.editMode = false;
        this.setChanged();
        this.user.recalculate();
    };

    Issue.prototype.doneEditingAll = function() {
        for (var i = 0; i < this.user.ra.users.length; i++) {
            var user = this.user.ra.users[i];
            for (var j = 0; j < user.issues.length; j++) {
                if (user.issues[j].editMode)
                    user.issues[j].doneEditing();
            }
        }
    };

    Issue.prototype.deletePastCustomAllocations = function() {
        this.customAllocation.deletePast();
    };

    Issue.prototype.split = function(date) {
        date.hours(0);
        date.minutes(0);
        date.seconds(0);
        if (!date.isSame(this.startdate, 'day') && !date.isSame(this.duedate.clone().add('days', 1), 'day')) {
            this.ra.loading();
            var self = this;
            this.worm.css('width', getDatePosition(date, this.ra) - this.worm.position().left);
            $.post(settings.splitIssueUrl,
                    {
                        issue_id: self.id,
                        date: date.format(settings.dateFormat)
                    }, function(data) {
                self.ra.loading();
                if (data.issue) {
                    var newIssue = new Issue(self.ra.unassigned, self.ra.unassigned.parseIssueData(data.issue, 1 + self.ra.unassigned.issues.indexOf(self)));
                    newIssue.menuItem.insertAfter(self.menuItem);
                    self.est -= newIssue.est;
                    self.estSpan.html('(' + Math.round(self.est * 100) / 100 + ')');
                    self.ra.unassigned.dropArea.css('height', self.ra.settings.rowHeight + self.ra.unassigned.dropArea.height());
                    for (var i = self.ra.unassigned.issues.indexOf(self) + 1; i < self.ra.unassigned.issues.length; i++) {
                        var issue = self.ra.unassigned.issues[i];
                        issue.rowIndex++;
                        issue.worm.css('top', issue.worm.position().top + settings.rowHeight);
                    }
                    for (var i = 0; i < self.ra.users.length; i++) {
                        var u = self.ra.users[i];
                        u.rowIndex++;
                        u.dropArea.css('top', u.dropArea.position().top + settings.rowHeight);
                        u.userAllocDiv.css('top', u.userAllocDiv.position().top + settings.rowHeight);
                        for (var j = 0; j < u.issues.length; j++) {
                            var issue = u.issues[j];
                            issue.rowIndex++;
                            issue.worm.css('top', issue.worm.position().top + settings.rowHeight);
                        }
                    }
                    self.ra.gridBody.css('height', self.ra.gridBody.height() + settings.rowHeight);
                    self.ra.ra.css('height', self.ra.ra.height() + settings.rowHeight);
                    self.ra.unassigned.issues.splice(self.rowIndex, 0, newIssue);
                    newIssue.worm.append(self.worm.children().not(".ui-resizable-handle").clone());
                }
            });

        }
    };

    Issue.prototype.setChanged = function() {
        if (this.readonly) {
            return false;
        }
        this.menuItem.addClass('changed').attr('title', settings.changed_title);
        this.changed = true;
    };

    Issue.prototype.setResized = function() {
        if (this.readonly) {
            return false;
        }
        this.menuItem.addClass('changed').attr('title', settings.changed_title);
        this.resized = true;
    };

    function Unassigned(ra, data) {
        this.ra = ra;
        this.rowIndex = 0;
        this.data = this.parseIssuesData(data);
        this.ignoredIssueIds = [];
        this.createMenuItem();
        this.createDropArea();
        this.createIssues();
    }

    Unassigned.prototype.createMenuItem = function() {
        this.menuItem = $('<li/>').append($('<a/>').attr('href', this.data.url).html(this.data.name)).appendTo(this.ra.userList);
    };

    Unassigned.prototype.createIssues = function() {
        this.issues = [];
        this.issueMenu = $('<ul/>').addClass('task-list').insertAfter(this.menuItem);
        for (var i = 0; i < this.data.issues.length; i++) {
            var data = this.data.issues[i];
            this.issues.push(new Issue(this, data));
        }
        this.dropArea.css('height', this.ra.settings.rowHeight * (1 + this.issues.length));
    }

    Unassigned.prototype.parseIssuesData = function(data) {
        for (var i = 0; i < data.issues.length; i++) {
            data.issues[i] = this.parseIssueData(data.issues[i], i);
        }
        return data;
    }

    Unassigned.prototype.parseIssueData = function(data, i) {
        data.rowIndex = 1 + this.rowIndex + i;
        data.start = moment(data.start);
        data.end = moment(data.end);
        data.startdate = moment(data.startdate);
        data.duedate = moment(data.duedate);
        data.originalstart = moment(data.originalstart);
        return data;
    }

    Unassigned.prototype.createDropArea = function() {
        var self = this;
        this.dropArea = $('<div/>')
                .addClass('drop-area')
                .css('top', 0)
                .css('height', 0)
                .appendTo(this.ra.gridBody)
                .droppable({
            activeClass: 'dropping',
            hoverClass: 'hover',
            drop: function(event, ui) {
                var issue = ui.draggable.data('issue');
                if (issue.user != self) {
                    issue.assignTo(self);
                } else {
                    issue.worm.css('top', (issue.rowIndex) * self.ra.settings.rowHeight);
                }
                issue.worm.css('left', getDatePosition(issue.startdate, issue.ra));
                issue.worm.css('width', getDatePosition(issue.duedate, issue.ra) - getDatePosition(issue.startdate, issue.ra) + issue.ra.settings.dayWidth).addClass('unassigned');
            }
        });
    };

    Unassigned.prototype.recalculate = function() {
        var self = this;
    };

    if (typeof patchResalloc == 'function') {
        patchResalloc({
            Resalloc: Resalloc,
            User: User,
            Issue: Issue,
            Unassigned: Unassigned,
            getPositionDate: getPositionDate,
            getDatePosition: getDatePosition
        });
    }

    function CustomAllocation(issue) {
        this.issue = issue;
        this.data = {};
    }

    CustomAllocation.prototype.allocate = function(date, hours) {
        if (hours || hours == 0)
            this.data[date.format(settings.dateFormat)] = hours;
        else {
            delete this.data[date.format(settings.dateFormat)];
        }
    }

    CustomAllocation.prototype.deleteAll = function() {
        this.data = {};
    };

    CustomAllocation.prototype.deletePast = function() {
        var newData = {};
        $.each(this.data, function(key, val) {
            if (moment(key).isAfter(moment())) {
                newData[key] = val;
            }
        });
        this.data = newData;
    };

})(jQuery);
