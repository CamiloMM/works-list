var path   = require('path');
var less   = require('less');
var fs     = require('fs');
var crypto = require('crypto');
var app    = require('../app');

function buildCss() {
    var code = fs.readFileSync('../stylesheets/all.less', {encoding: 'utf8'});
    var options = {
        paths        : ['../stylesheets'],
        optimization : 2,
        filename     : "all.less",
        compress     : true,
        cleancss     : true
    };
    var parser = new less.Parser(options);
    parser.parse(code, function(error, cssTree) {
        if (error) { return less.writeError(error, options); }

        // Create the CSS from the cssTree
        var css = cssTree.toCSS({
            compress: options.compress,
            cleancss: options.yuicompress
        });

        app.set('css', {
            md5:  crypto.createHash('md5').update(css).digest('hex'),
            code: css
        });
    });
}

// This setup mechanism is invoked before starting the server.
function setup() {
    buildCss();
}

module.exports = setup;
