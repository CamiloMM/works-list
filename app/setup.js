var path    = require('path');
var less    = require('less');
var fs      = require('fs');
var crypto  = require('crypto');
var app;

function buildCss() {
    var originalDirectory = process.cwd();
    process.chdir(__dirname + '/../stylesheets');
    var code = fs.readFileSync(process.cwd() + '/all.less', {encoding: 'utf8'});
    var options = {
        paths        : [process.cwd()],
        optimization : 2,
        filename     : "all.less",
        compress     : true,
        cleancss     : true
    };
    var parser = new less.Parser(options);
    parser.parse(code, function(error, cssTree) {
        if (error) { return less.writeError(error, options); }

        var css = cssTree.toCSS({
            compress: options.compress,
            cleancss: options.yuicompress
        });

        app.set('css', {
            md5:  crypto.createHash('md5').update(css).digest('hex'),
            code: css
        });

        process.chdir(originalDirectory);
    });
}

// This setup mechanism is invoked before starting the server.
function setup(instance) {
    app = instance;
    buildCss();
}

module.exports = setup;
