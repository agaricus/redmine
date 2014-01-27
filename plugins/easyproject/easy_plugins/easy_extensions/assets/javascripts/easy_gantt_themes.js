$(function() {
	var headerColor = $('#header-color');
	var headerFontColor = $('#header-font-color');
	var preview = $('#header-style-preview');

	function isColor(string) {
		return !!string.match(/#(\d|[a-f]){6}/i);
	}

	$('#header-colorpicker').farbtastic(function(color) {
		headerColor.val(color);
		preview.css('background-color', color);
	});
	var headerColorPicker = $.farbtastic('#header-colorpicker');
	$('#header-font-colorpicker').farbtastic(function(color) {
		headerFontColor.val(color);
		preview.css('color', color);
	});
	var headerFontColorPicker = $.farbtastic("#header-font-colorpicker");

	if (isColor(headerColor.val())) {
		headerColorPicker.setColor(headerColor.val());
	}
	if (isColor(headerFontColor.val())) {
		headerFontColorPicker.setColor(headerFontColor.val());
	}
});
