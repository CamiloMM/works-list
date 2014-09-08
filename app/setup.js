var path       = require('path');
var less       = require('less');
var fs         = require('fs');
var crypto     = require('crypto');
var chokidar   = require('chokidar');
var browserify = require('browserify');
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
        cleancss     : true,
        ieCompat     : false
    };
    var parser = new less.Parser(options);
    parser.parse(code, function(error, cssTree) {
        if (error) { return less.writeError(error, options); }

        var css = cssTree.toCSS(options);

        app.set('css', {
            md5:  crypto.createHash('md5').update(css).digest('hex'),
            code: css
        });

        process.chdir(originalDirectory);
    });
}

function watchCss() {
    var watcher = chokidar.watch(path.normalize(__dirname + '/../stylesheets'));
    var timeout = null;
    watcher.on('all', function change() {
        if (timeout) {
            clearTimeout(timeout);
            timeout = null;
        }
        timeout = setTimeout(function() {
            buildCss();
            timeout = null;
        }, 150);
    });
}

function buildJs() {
    var originalDirectory = process.cwd();
    process.chdir(__dirname + '/../scripting');
    var b = browserify();
    b.add('./main.js');
    b.bundle(function(err, buf) {
        if (err) {
            var js = 'alert("JS build error!\n\n"+' + JSON.stringify(String(err)) + ');';
        } else {
            var js = buf.toString();
        }

        app.set('js', {
            md5:  crypto.createHash('md5').update(js).digest('hex'),
            code: js
        });
    })
    process.chdir(originalDirectory);
}

function watchJs() { // TODO: DRY this up.
    var watcher = chokidar.watch(path.normalize(__dirname + '/../scripting'));
    var timeout = null;
    watcher.on('all', function change() {
        if (timeout) {
            clearTimeout(timeout);
            timeout = null;
        }
        timeout = setTimeout(function() {
            buildJs();
            timeout = null;
        }, 150);
    });
}

// This setup mechanism is invoked before starting the server.
function setup(instance) {
    app = instance;
    buildCss();
    watchCss();
    buildJs();
    watchJs();
}

module.exports = setup;
