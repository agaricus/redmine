$(document).ready(function () {

	setInfiniteScrollDefaults();

	$('table.list.projects:first > tbody').infinitescroll({
		navSelector: 'p.pagination',
		nextSelector: 'p.pagination > a.next',
		itemSelector: 'table.list.projects:first > tbody > tr, p.pagination > a.next'
	}, function(data, opts) {
		var a = $(data.pop());
		if(a.is('a')) {
			opts.path = [a.attr('href')];
			a.remove();
		} else {
			data.push(a[0]);
			opts.state.isPaused = true;
		}
	});

	// project search
	var timeoutId;
	$('#easy_query_q').keyup(function(e) {
		if(timeoutId) clearTimeout(timeoutId);
		timeoutId = setTimeout(projectSearch, 300);
	});

	var projects = $('table.projects > tbody');
	function projectSearch() {
		var q =  $('#easy_query_q').val();
		if(!q || q.length < 3) return false;
		$('#ajax-indicator').show();
		$.post('/projects/search?for=projects', $('#query_form, #easy_query_q').serialize(), function(resp) {
			window.resp = resp;
			projects.empty().append($('tbody > tr', resp)).infinitescroll('pause');
			$('p.pagination').remove();
			$('#ajax-indicator').hide();
			$('.selector').infinitescroll('pause');
		});
	}

	$('span.root-expander').live('click', function () {
		var $this = $(this),
			tr = $this.closest('tr'),
			childRows;

		if ($this.hasClass('open')) {
			childRows = tr.nextUntil('tr.root').remove();
			$this.removeClass('open');
		} else {
			$.get(window.location.href, {
				root_id: $this.data().id
			}, function (resp) {
				$this.addClass('open');
        $(resp).find('table.projects tbody:first').children("tr").insertAfter(tr);
			});
		}
	});

	$('span.descendant-expander').live('click', function () {
		var $this = $(this),
			data = $this.data(),
			tr = $this.closest('tr'),
			childRows;

		if ($this.hasClass('open')) {
			childRows = tr.nextUntil('tr.' + tr.attr('class').match(/idnt-\d+/)[0]);
			childRows.hide();
			$('span.expander.open', childRows).removeClass('open');
			$this.removeClass('open');
		} else {
			$('tr.' + data.prefix + 'parentproject_' + data.id).show();
			$this.addClass('open');
		}
	});

});
