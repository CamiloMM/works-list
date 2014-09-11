var $ = require('jquery');

var pages = [
    require('./src/signup-and-login')
];

$(function() {
    for (var i = 0; i < pages.length; i++) {
        pages[i]($);
    };
});
