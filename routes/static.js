var express  = require('express');
var router   = express.Router();

router.get('/static/:path(*)', function(req, res) {
    var types = {css: 'text/css', js: 'application/javascript'};

    for (type in types) {
        var compiled = req.app.get(type);
        var pattern = new RegExp('^' + compiled.md5 + '\\.' + type + '$');

        if (pattern.test(req.params.path)) {
            res.set('Content-Type', types[type]);
            res.set('Cache-Control', 'public, max-age=31536000'); // A year.
            res.set('Expires', new Date(Date.now() + 31536000000).toUTCString());
            res.send(compiled.code);
            return;
        }
    }

    res.send(404, 'Not found!');
});

module.exports = router;
