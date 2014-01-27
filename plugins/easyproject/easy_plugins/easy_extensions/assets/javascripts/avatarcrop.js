//Avatar cropping
$(document).ready(function() {
	$('img.gravatar').Jcrop({
		setSelect: [0,0,1000,1000],
		onSelect: function(c) {
			$("#crop_x").val(c.x);
			$("#crop_y").val(c.y);
			$("#crop_width").val(c.w);
			$("#crop_height").val(c.h);	
		}
	});
});