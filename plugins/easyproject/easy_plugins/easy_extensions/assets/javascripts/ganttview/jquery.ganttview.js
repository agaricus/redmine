/*jslint browser: true, nomen: true*/
/*global jQuery, moment*/
(function ($) {
    "use strict";

    $.widget("ui.ganttview", {

        // default options
        options: {
            startDate: moment(),
            zoom: "week", // day, week or month
            grid: [24, 22], // [cell width, cell height]
            defaultDays: 300, // number of days to be displayed before data is loaded
            calendarMonthFormat: "MMMM YYYY", // moment.js format for months in calendar
            holidays: [], // array of repeating or one of holidays, example: [{date: "2010-07-24", isRepeating: true}]
            markFreeDays: true, // mark free days in calendar and grid
            splitter: true, // splitter which allows resizing menu and grid
            infiniteTimeline: true, // if true, days are automatically added when user scrolls towards the end of the timeline
            singleColumnMenu: true, // true if there is only one column in the menu
            menuColumnNames: null, // null or array of names of columns displayed in the menu
            columnWidths: null, // null or array of specified column widths
            menuTableWidth: "110%" // width of the menu table
        },

        items: [],

        _create: function () {
            this.element.addClass("easy-ganttview");
            $.each(this.options.holidays, function () {
                this.date = moment(this.date);
            });
            this._refresh();
        },

        _refresh: function () {
            this._refreshLayout();

            this.startDate = this.options.startDate.clone();
            this.endDate = this.options.startDate.clone().subtract(1, "day");

            this._initCalendar();
        },

        _setOptions: function () {
            this._superApply(arguments);
            this._refresh();
        },

        _refreshLayout: function () {
            this.element.empty();
            this._createMenu();
            this._createGrid();
            $("<div/>")
                .addClass("clear")
                .appendTo(this.element);
            if (this.options.splitter) {
                this._enableSplitter();
            }
        },

        _createMenu: function () {
            this.menuContainer = $("<div/>")
                .addClass("menu-container")
                .appendTo(this.element);

            this.menuHeader = $("<table/>")
                .addClass("menu-header")
                .css("width", this.options.menuTableWidth)
                .appendTo(this.menuContainer);

            if ($.isArray(this.options.menuColumnNames)) {
                this._fillMenuHeader();
            }

            this.menuScroller = $("<div/>")
                .addClass("menu-scroller")
                .appendTo(this.menuContainer);

            this.menuTable = $("<table/>")
                .addClass("menu")
                .css("width", this.options.menuTableWidth)
                .appendTo(this.menuScroller);

            if (this.options.singleColumnMenu) {
                this.menuTable.addClass("single-column");
            }

            this.menu = $("<tbody/>")
                .appendTo(this.menuTable);
        },

        _fillMenuHeader: function () {
            var thead = $("<thead/>").appendTo(this.menuHeader),
                tr = $("<tr/>").appendTo(thead),
                self = this;

            $.each(this.options.menuColumnNames, function (i) {
                $("<td/>")
                    .html(this)
                    .css("width", self.options.columnWidths[i])
                    .appendTo(tr);
            });
        },

        _createGrid: function () {
            this.gridContainer = $("<div/>")
                .addClass("grid-container")
                .appendTo(this.element);

            this._createGridHeader();
            this._createGridBody();
        },

        _createGridHeader: function () {
            var calendar, calendarTbody;

            this.gridHeaderContainer = $("<div/>")
                .addClass("grid-header-container")
                .appendTo(this.gridContainer);

            this.gridHeader = $("<div/>")
                .addClass("grid-header")
                .appendTo(this.gridHeaderContainer);

            calendar = $("<table/>")
                .addClass("calendar")
                .appendTo(this.gridHeader);

            calendarTbody = $("<tbody/>").appendTo(calendar);

            this.calendar = {
                table: calendar,
                tbody: calendarTbody,
                topRow: $("<tr/>").appendTo(calendarTbody).addClass("top-row"),
                bottomRow: $("<tr/>").appendTo(calendarTbody).addClass("bottom-row")
            };
        },

        _createGridBody: function () {
            var self = this;

            this.gridBodyContainer = $("<div/>")
                .addClass("grid-body-container")
                .appendTo(this.gridContainer)
                .scroll(function () {
                    self._gridBodyScroll();
                });

            this.gridBody = $("<div/>")
                .addClass("grid-body")
                .appendTo(this.gridBodyContainer);
        },

        _enableSplitter: function () {
            var self = this;
            this.menuContainer.resizable({
                helper: "splitter-helper",
                handles: "e",
                minWidth: 180,
                stop: function () {
                    // workaround because ui.size.width gives wrong values when you drag fast
                    self.gridContainer.hide();
                    setTimeout(function () {
                        self.gridContainer.css("width", self.element.width() - self.menuContainer.outerWidth());
                        self.gridContainer.show();
                    }, 100);
                }
            });
        },

        _gridBodyScroll: function () {
            var scrollRatio = (this.gridBodyContainer.scrollLeft() + this.gridBodyContainer.width()) / this.gridBody.width();
            this.gridHeaderContainer[0].scrollLeft = this.gridBodyContainer[0].scrollLeft;
            this.menuScroller[0].scrollTop = this.gridBodyContainer[0].scrollTop;
            if (scrollRatio > 0.95) {
                this._addDays(7);
            }
        },

        _initCalendar: function () {
            var i;

            for (i = 0; i < this.options.defaultDays; i += 1) {
                this._addDay();
            }
        },

        _addDays: function (n) {
            for (var i = 0; i < n; i++) {
                this._addDay();
            }
        },

        _addDay: function () {
            var monthTd = $("td:last", this.calendar.topRow),
                newEndDate = this.endDate.clone().add(1, "day"),
                monthColspan;

            if (newEndDate.month() !== this.endDate.month() || monthTd.length === 0) {
                monthTd = $("<td/>")
                    .append($("<span/>").html(newEndDate.format(this.options.calendarMonthFormat)))
                    .attr("colspan", 0)
                    .appendTo(this.calendar.topRow);
            }

            $("<td/>")
                .append($("<span/>").html(newEndDate.date()))
                .appendTo(this.calendar.bottomRow);

            monthColspan = parseInt(monthTd.attr("colspan"), 10) + 1;
            monthTd.attr("colspan", monthColspan);
            $("span", monthTd).css("max-width", monthColspan * this.options.grid[0] - 1);

            this.endDate = newEndDate;
            this._afterDaysAdded();
        },

        _afterDaysAdded: function () {
            this.gridBody.css("width", (this.endDate.diff(this.startDate, "days")) * this.options.grid[0]);
            if (this.options.markFreeDays && this.isFreeDay(this.endDate)) {
                this._markLastDayAsFree();
            }
        },

        _markLastDayAsFree: function () {
            $("td:last", this.calendar.bottomRow).addClass("free-day");
            $("<div/>")
                .addClass("free-day")
                .appendTo(this.gridBody)
                .css("width", this.options.grid[0])
                .css("top", 0)
                .css("left", this.gridBody.width())
                .css("height", "100%");
        },

        _getRowTop: function (i) {
            return this.options.grid[1] * i;
        },

        _getDatePosition: function (date) {
            return date.diff(this.startDate, "days") * this.options.grid[0];
        },

        _createItemMenuItem: function (item, options) {
            var menuAry = $.isArray(options.menuContent) ? options.menuContent : [options.menuContent];
            item.menuItem = $("<tr/>").appendTo(this.menu);

            $.each(menuAry, function (i) {
                if (i == 0 && options.url) {
                    item.menuItem.append($("<td/>")
                        .append($("<a/>").attr("href", options.url).html(this))
                    );
                } else {
                    item.menuItem.append($("<td/>").html(this));
                }
            });
        },

        _createItemWorm: function (item, options) {
            var top = this._getRowTop(this.items.length),
                left = this._getDatePosition(item.startDate),
                width = this._getDatePosition(item.endDate) - left;

            item.worm = $("<div/>")
                .addClass("worm")
                .addClass(options.style)
                .appendTo(this.gridBody)
                .css({
                    top: top,
                    left: left,
                    width: width - 1
                })
                .html(options.wormContent);
        },

        _createProgress: function (item, options) {
            item.progress = options.progress || 0;
            item.progressDiv = $("<div/>")
                .addClass("progress")
                .appendTo(item.worm)
                .css("width", '' + Math.round(item.progress) + '%');
        },

        _setColumnWidths: function () {
            var self = this;
            $("td", this.items[0].menuItem).each(function (i) {
                $(this).css("width", self.options.columnWidths[i]);
            });
        },

        _ensureEndDate: function (date) {
            while(this.endDate.isBefore(date)) {
                this._addDay();
            }
        },

        // public methods

        addItem: function (options) {
            var item = {
                startDate: options.startDate ? moment(options.startDate) : null,
                endDate: options.endDate ? moment(options.endDate) : null
            };

            this._createItemMenuItem(item, options);
            if (item.startDate && item.endDate) {
                this._ensureEndDate(item.endDate);
                this._createItemWorm(item, options);
            }
            this._createProgress(item, options);

            var currentHeight = this.gridBody.height();
            this.gridBody.css("height", currentHeight + this.options.grid[1]);
            this.items.push(item);
            if (this.items.length === 1) {
                this._setColumnWidths();
            }
            return item;
        },

        refresh: function () {
            this._refresh();
        },

        isWeekend: function (date) {
            return date.day() === 6 || date.day() === 0;
        },

        isHoliday: function (date) {
            var isHoliday = false;
            $.each(this.options.holidays, function () {
                if (this.date.isSame(date) || (this.isRepeating && (this.date.date() === date.date() && this.date.month() === date.month()))) {
                    isHoliday = true;
                    return false;
                }
            });
            return isHoliday;
        },

        isWorkingDay: function (date) {
            return !this.isWeekend(date) && !this.isHoliday(date);
        },

        isFreeDay: function (date) {
            return !this.isWorkingDay(date);
        },

    });

}(jQuery));
