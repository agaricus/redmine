(function ($){

	var settings = {
		dayWidth: 24,
		rowHeight: 22,
		loadUrl: '/user_allocation_gantt/data_by_project.json',
		saveProjectsUrl: '/user_allocation_gantt/save_projects',
		loadParams: function () {
			return {
				period_type: $('input[name="filters[period_type]"]:checked').val(),
				period: $('#filters_period').val(),
				from: $('#period_from').val(),
				to: $('#period_to').val()
			};
		},
		dateFormat: 'yyyy-MM-dd',
		saveCallback: function (container, response) {
			$('div.resalloc-flash').remove();
			var fl = $('<div/>').addClass('flash resalloc-flash').addClass(response.type).append($('<span/>').html(response.html)).insertBefore(container);
			setTimeout(function () {
				fl.fadeOut('slow', function () {fl.remove()});
			}, 4000);
		},
		todayLine: true
	}

	$.fn.resalloc = function (options, methodParams) {
		//init
		var ra;
		if(typeof options == 'object') {
			settings = $.extend(settings, options);
			ra = new Resalloc($(this), settings);
			$.data(this[0], 'resalloc', ra);
		}
		//method calling
		else if(typeof options == 'string') {
			ra = $.data(this[0], 'resalloc');
			switch(options) {
			case 'applyFilters':
				ra.clean();
				ra.loadData(this.settings.loadUrl, this.settings.loadParams);
				break;
			case 'saveProjects':
				ra.saveProjects();
				break;
			}
		}
	};

	function Resalloc(container, settings) {
		var resalloc = this;
		this.container = container;
		this.settings = settings;
		this.ra = $('<div/>').appendTo(this.container).addClass('resalloc resalloc-by-project').css('height',
			window.innerHeight - this.container[0].offsetTop - 60);
		this.projectListContainer = $('<div/>').addClass('user-list-container').appendTo(this.ra).resizable({
			resize: function (event, ui) {
				$('.resalloc-splitter').css('height', resalloc.gridBodyContainer.height());
			},
            stop: function (event, ui) {
            	resalloc.gridContainer.hide();
                setTimeout(function () {
                    resalloc.afterSplitterResize();
                },100);
            },
            helper: 'resalloc-splitter',
            handles: 'e',
            minWidth: 180,
            maxWidth: 700
        });
		this.projectList = $('<ul/>').addClass('user-list').appendTo(this.projectListContainer);

		var gc = $('<div/>').addClass('grid-container').appendTo(this.ra);
		this.gridContainer = gc;
		this.gridHeaderContainer = $('<div/>').addClass('grid-header-container').appendTo(gc);
		this.gridHeader = $('<div/>').addClass('grid-header').appendTo(this.gridHeaderContainer);
		this.gridBodyContainer = $('<div/>').appendTo(gc).addClass('grid-body-container');
		this.gridBody = $('<div/>').addClass('grid-body').appendTo(this.gridBodyContainer);
		this.gridBodyContainer.css('height', this.ra.height() - 2*settings.rowHeight);
		this.gridBodyContainer.scroll(function (e) {
			resalloc.afterScroll(this, e);
		});

		this.loadData(this.settings.loadUrl, this.settings.loadParams);
		this.projects = [];
	}

	Resalloc.prototype.afterScroll = function (el, e) {
		$(this.gridHeaderContainer)[0].scrollLeft = el.scrollLeft;
		$(this.projectListContainer)[0].scrollTop = el.scrollTop;
	};

	Resalloc.prototype.afterSplitterResize = function () {
		this.gridContainer.css('width', this.ra.width() - (this.projectListContainer.outerWidth() + 5)).show();
	};

	Resalloc.prototype.createCalendar = function () {

		var d = this.start.clone();
		var mc;
		var monthDiv;
		var daysDiv;

		var width = 2 + (1 + countDays(this.start, this.end))*this.settings.dayWidth;
		this.gridHeader.css('width', width);
		this.gridBody.css('width', width);

		while (d.isBefore(this.end)) {
			if(!mc || d.date() == 1) {
				mc = $('<div/>').addClass('month-container').appendTo(this.gridHeader);
				var text = d.year() + '/' + (d.month() + 1);
				monthDiv = $('<div/>').addClass('month').append(text).attr('title', text).appendTo(mc);
				dayDiv = $('<div/>').addClass('days').appendTo(mc);
			}
			var ds = $('<span/>').append(d.date()).appendTo(dayDiv);
			if(d.day() === 6 || d.day() === 0) ds.addClass('weekend');
			d.add(1, 'day');
			monthDiv.css('width', dayDiv.children().length * settings.dayWidth - 8);
		}

		if(this.settings.todayLine) this.createTodayLine();

		var bgPos = datePosition(this.start.clone().day(8), this);
		this.gridBody.css('background-position-x', bgPos).css('background-position', bgPos + 'px 0');
	}

	Resalloc.prototype.createTodayLine = function () {
		$('<div/>').html('&nbsp;').addClass('todayLine').css('left', datePosition(moment(), this) + this.settings.dayWidth / 2).appendTo(this.gridBody);
	}

	Resalloc.prototype.clean = function () {
		this.gridHeader.empty();
		this.gridBody.empty();
		this.projectList.empty();

		this.projects = [];
		this.start = null;
		this.end = null;
		this.data = null;
	}

	Resalloc.prototype.loading = function () {
	}

	Resalloc.prototype.loadData = function (url, params) {
		this.loading();
		var ra = this;
		$.getJSON(url, typeof params == 'function' ? params() : params, function (data) {

			if(data.start) ra.start = moment(data.start);
			if(data.end) ra.end = moment(data.end);
			ra.createCalendar();
			ra.createRows(data);
			ra.loading();
		});
	}

	Resalloc.prototype.createRows = function (data) {
		if (typeof data.projects == 'object') {
			var rowCount = 0;
			for (var i = 0; i < data.projects.length; i++) {
				this.projects.push(new Project(data.projects[i], i, this));
				rowCount += 1 + this.projects[this.projects.length - 1].users.length;
			}
		}
		this.gridBody.css('height', this.settings.rowHeight*rowCount);
		this.projectList.css('height', this.settings.rowHeight*rowCount + 100);
		if(this.ra.height() > (rowCount + 3)*this.settings.rowHeight) {
			this.setHeight((rowCount + 3)*this.settings.rowHeight);
		}
	}

	Resalloc.prototype.reload = function () {
		this.clean();
		this.loadData(this.settings.loadUrl, this.settings.loadParams);
	};

	Resalloc.prototype.changedProjects = function (changedProjects) {
		changedProjects = [];
		for (var i = 0; i < this.projects.length; i++) {
			var changedusers = this.projects[i].changedusersData();
			if (((function (obj) {for(var i in obj) return true;})(changedusers))) {
				changedProjects.push({id: this.projects[i].data.id, users: changedusers});
			}
		}
		return changedProjects;
	}

	Resalloc.prototype.expandIfNeeded = function (x) {
		var spaceLeft = parseFloat(this.gridBody.css('width')) - x;
		if(spaceLeft < this.settings.dayWidth*2) {
			this.addDays(7);
		}
	}

	Resalloc.prototype.addDays = function (n) {
		for(var i = 0; i < n; i++) this.addDay();
	}

	Resalloc.prototype.addDay = function () {
		var newEnd = this.end.clone().add(1, 'day');
		var daysDiv, monthDiv;
		if(newEnd.month() == this.end.month()) {
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
		if(newEnd.day() === 6 || newEnd.day() === 0) ds.addClass('weekend');
		monthDiv.css.width(daysDiv.children().length*settings.dayWidth - 8);

		this.end = newEnd;
	}

	Resalloc.prototype.saveProjects = function () {
		var self = this;
		this.loading();
		var changedProjects = {};
		for (var i = 0; i < this.projects.length; i++) {
			if (this.projects[i].changed) {
				var project = this.projects[i];
				var movement = countDays(project.start, getPositionDate(project.worm.position().left, this));
				changedProjects[project.data.id.toString()] = movement
			}
		}
		$.post(this.settings.saveProjectsUrl, {projects: changedProjects}, function (response) {
			self.settings.saveCallback(self.container, response);
			$('div.resalloc li.changed').removeClass('changed').attr('title', '');
			self.loading();
			self.reload();
		});
	}

	Resalloc.prototype.setHeight = function (h) {
		this.ra.css('height', h);
		this.projectListContainer.css('height', this.ra.height() - 2*this.settings.rowHeight);
		this.gridBodyContainer.css('height', this.ra.height() - 2*this.settings.rowHeight);
	};

	Resalloc.prototype.flash = function (messages, type) {
		$('div.resalloc-flash').remove();
		var fl = $('<div/>').addClass('flash resalloc-flash').addClass(type).append($('<span/>').html(messages)).insertBefore(this.container);
		setTimeout(function () {
			fl.fadeOut('slow', function () {fl.remove()});
		}, 4000);
	};


	function countDays(start, end) {
		return Math.round((end - start)/(3600000*24));
	}

	function datePosition(d, ra) {
		return (countDays(ra.start, d))*ra.settings.dayWidth;
	}

	function getPositionDate(p, ra) {
		return ra.start.clone().add(p/ra.settings.dayWidth, 'day');
	}

	function findProject(projects, id) {
		for(var i = 0; i < projects.length; i++) {
			if(projects[i].data.id == id) return projects[i];
		}
	}

	function findUser(users, id) {
		for(var i = 0; i < users.length; i++) {
			if(users[i].id == id) return users[i];
		}
	}

	function Project(projectData, rowIndex, ra) {
		this.data = projectData;
		this.ra = ra;
		this.rowIndex = this.defaultRowIndex();
		for (var i = 0; i < this.ra.projects.length; i++) {
			this.rowIndex += 1 + this.ra.projects[i].users.length;
		}
		this.users = [];
		this.start = moment(this.data.start);
		this.end = moment(this.data.end);
		this.allocations = [];
		var d = this.start.clone();
		while (d <= this.end) {
			this.allocations.push(0);
			d.add(1, 'day');
		}
		this.createMenuItem();
		this.createUsers();
		this.createWorm();
	}

	Project.prototype.createUsers = function () {
		this.userMenu = $('<ul/>').addClass('task-list').insertAfter(this.menuItem);
		if(this.data.users && this.data.users.length > 0) {
			for (var i = 0; i < this.data.users.length; i++) {
				var userData = this.data.users[i];
				userData.rowIndex = this.rowIndex + i + 1;
				this.users.push(new User(this, userData));
			}
		}
	};

	Project.prototype.defaultRowIndex = function () {
		return this.ra.unassigned ? this.ra.unassigned.users.length	 + 1 : 0;
	};

	Project.prototype.createMenuItem = function () {
		this.menuItem = $('<li/>').append($('<a/>').attr('href', this.data.href).attr('title', this.data.name).html(this.data.name)).appendTo(this.ra.projectList);
		var currentProject = this;
		if(!this.data.entities || this.data.entities.length == 0) {
			this.menuItem.addClass('no-issues');
		}
	};

	Project.prototype.levelPrefix = function () {
		return Array(this.data.level).join('&nbsp;&nbsp;&nbsp;');
	};

	Project.prototype.createWorm = function () {
		if (this.start > this.end) {
			return;
		}
		var self = this;
		this.worm = $('<div/>').addClass('worm').appendTo(this.ra.gridBody);
		if(this.allocations) {
			for(var i = 0; i < this.allocations.length; i++) {
				var alloc = this.allocations[i], allocSpan = $('<span/>').appendTo(this.worm);
				if (alloc <= 0) {
					allocSpan.addClass('no-hours');
				}
				allocSpan.html(Math.floor(alloc));
				var decimal = alloc - Math.floor(alloc, 10);
				if (decimal > 0) {
					allocSpan.append('.').append('<span class="">' + Math.round(decimal*10) + '</span>');
				}
			}
		}
		this.worm.css('left', datePosition(this.start, this.ra));
		this.worm.css('top', this.rowIndex * this.ra.settings.rowHeight);

		if(typeof this.wormtitle == 'string') this.worm.attr('title', this.wormtitle);

		if(this.readonly) {
			this.worm.addClass('readonly');
			return this;
		}

		if(this.is_planned) {
			this.worm.css('background-size', '100% 100%').addClass('planned');
		}

		if(settings.readonly) {
			this.worm.css('cursor', 'default');
			return;
		}
		this.worm.draggable({
			// containment: 'parent',
			axis: 'x',
			grid:[24, 22],
			stop: function (event, ui) {
				self.setChanged();
			}
		});

		this.worm.data('project', this);
	}

	Project.prototype.setChanged = function () {
		if(this.readonly) return false;
		this.menuItem.addClass('changed').attr('title', settings.changed_title);
		this.changed = true;
	};

	function User(project, data) {
		for(p in data) {
			this[p] = data[p];
		}
		this.project = project;
		this.ra = this.project.ra;
		this.createMenuItem();
		this.createAllocation();
	}

	User.prototype.createMenuItem = function () {
		var self = this;
		if(this.menuItem) this.menuItem.empty();
		else this.menuItem = $('<li>').appendTo(this.project.userMenu);
		this.menuItem
			.append($('<a/>')
			.attr('title', this.name)
			.html(this.name)
			.attr('href', this.href ? this.href : 'javascript:void(0);'))
			.addClass(this.css_classes);
		if(this.project) this.menuItem.append($('<a/>').attr('title', this.project).attr('href', this.projecthref).html(this.project));
		if(this.est) {
			this.menuItem.append($('<span/>').html('(' + this.est + ')').click(function () {
				self.editEstimatedHours();
			}));
		}
	};

	User.prototype.createHoursSum = function (hours) {
		if (hours > 0) {
			$('<span/>')
				.html('(' + Math.round(hours) + ')')
				.appendTo(this.menuItem);
		}
	};

	User.prototype.createAllocation = function () {
		var self = this;
		var hoursSum = 0;

		this.projectAllocDiv = $('<div/>').appendTo(this.ra.gridBody).addClass('user-allocation').css('top', this.rowIndex * this.ra.settings.rowHeight);
		if (this.allocations) {
			var projectAllocIndex = Math.round((this.ra.start - this.project.start)/8.64e7)
			for (var i = 0; i < this.allocations.length; i++) {
				var alloc = this.allocations[i];
				hoursSum += alloc.hours;
				if (alloc.hours && this.project.allocations.length >= projectAllocIndex + i && projectAllocIndex + i >= 0) {
					this.project.allocations[projectAllocIndex + i] += alloc.hours;
				}
				var allocSpan = $('<span/>').appendTo(this.projectAllocDiv).addClass(alloc.over ? 'over' : '').attr('title', alloc.activity_name);
				allocSpan.html(Math.floor(alloc.hours));
				var decimal = alloc.hours - Math.floor(alloc.hours, 10);
				if (decimal > 0) {
					allocSpan.append('.').append('<span class="decimal">' + Math.round(decimal*10) + '</span>');
				}
				if (alloc.hours == 0) {
					allocSpan.addClass('no-hours');
				}
			};
		}

		if (hoursSum > 0) {
			this.createHoursSum(hoursSum);
		}
	};

})(jQuery);
