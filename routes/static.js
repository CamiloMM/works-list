var express  = require('express');
var router   = express.Router();

router.get('/static/:path(*)', function(req, res) {
    var css = req.app.get('css');
    var js  = req.app.get('js');
    var cssPattern = new RegExp('^' + css.md5 + '\\.css$');
    var jsPattern  = new RegExp('^' + js.md5  +  '\\.js$');

    if (cssPattern.test(req.params.path)) {
        res.set('Content-Type', 'text/css');
        res.set('Cache-Control', 'public, max-age=31536000'); // A year.
        res.set('Expires', new Date(Date.now() + 31536000000).toUTCString());
        res.send(css.code);
    } else if (jsPattern.test(req.params.path)) {
        res.set('Content-Type', 'application/javascript');
        res.set('Cache-Control', 'public, max-age=31536000'); // A year.
        res.set('Expires', new Date(Date.now() + 31536000000).toUTCString());
        res.send(js.code);
    } else {
        res.send(404, 'Not found!');
    }
});

module.exports = router;
