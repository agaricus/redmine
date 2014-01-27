// Edit to suit your needs.
var ADAPT_CONFIG;
// Hack for IE8
if (getInternetExplorerVersion() == 8) {
  ADAPT_CONFIG = {
    // Where is your CSS?
    path: '/plugin_assets/easy_extensions/themes/easy_widescreen/grid/',

    // false = Only run once, when page first loads.
    // true = Change on window resize and page tilt.
    dynamic: true,

    // First range entry is the minimum.
    // Last range entry is the maximum.
    // Separate ranges by "to" keyword.
    range: [
      '0px  to 980px    = 960.min.css',
      '980px  to 1280px = 960.min.css',
      '1280px to 1600px = 1200.min.css',
      '1600px to 1940px = 1560.min.css',
      '1940px to 2540px = 1920.min.css',
      '2540px           = 2520.min.css'
    ]
  };
}