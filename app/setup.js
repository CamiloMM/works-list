var path       = require('path');
var less       = require('less');
var fs         = require('fs');
var crypto     = require('crypto');
var chokidar   = require('chokidar');
var browserify = require('browserify');
var UglifyJS   = require("uglify-js");
var app;

function buildCss(next) {
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
        next();
    });
}

function buildJs(next) {
    var b = browserify();
    b.add('./main.js');
    b.bundle(function(err, buf) {
        if (err) {
            var js = 'alert("JS build error!\n\n"+' + JSON.stringify(String(err)) + ');';
        } else {
            var js = buf.toString();
        }

        var options = {
            fromString : true,
            mangle     : {screw_ie8: true},
            compress   : {
                booleans      : true,
                cascade       : true,
                comparisons   : true,
                conditionals  : true,
                dead_code     : true,
                drop_console  : true,
                drop_debugger : true,
                evaluate      : true,
                hoist_funs    : true,
                if_return     : true,
                join_vars     : true,
                loops         : true,
                negate_iife   : true,
                properties    : true,
                screw_ie8     : true,
                sequences     : true,
                unused        : true
            }
        };

        var minified = UglifyJS.minify(js, options).code;

        app.set('js', {
            md5:  crypto.createHash('md5').update(minified).digest('hex'),
            code: minified
        });
        next();
    })
}

// Auto-compilation abstraction. You give it a directory path, and a compilation routine.
// The routine will be executed in the directory specified, and this directory will be
// watched for changes, running this compile step again when changes are detected.
// If the routine needs to be async, we'll pass it a "next" argument.
function autoCompile(directory, routine) {
    var absolute = path.resolve(__dirname, directory);
    function compile() {
        var originalDirectory = process.cwd();
        process.chdir(absolute);
        if (routine.length) {
            routine(function() { process.chdir(originalDirectory); });
        } else {
            routine();
        }
    }
    compile();
    var watcher = chokidar.watch(absolute);
    var timeout = null;
    watcher.on('all', function change() {
        if (timeout) {
            clearTimeout(timeout);
            timeout = null;
        }
        timeout = setTimeout(function() {
            compile();
            timeout = null;
        }, 150);
    });
}

// This setup mechanism is invoked before starting the server.
function setup(instance) {
    app = instance;
    autoCompile('../stylesheets', buildCss);
    autoCompile('../scripting', buildJs);
}

module.exports = setup;
