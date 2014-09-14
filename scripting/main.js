var $        = require('jquery');
var utils    = require('./src/utils.js');
var autoload = require('./src/autoload.js')

var pages = [
    require('./src/signup-and-login')
];

$(function() {
    autoload($, utils);
    for (var i = 0; i < pages.length; i++) {
        pages[i]($, utils);
    };
});
