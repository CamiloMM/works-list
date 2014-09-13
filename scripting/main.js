var $     = require('jquery');
var utils = require('./src/utils.js');

var pages = [
    require('./src/signup-and-login')
];

$(function() {
    for (var i = 0; i < pages.length; i++) {
        pages[i]($, utils);
    };
});
