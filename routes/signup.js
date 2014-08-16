var express = require('express');
var router = express.Router();

// Signup page. Depends on a configured express app object.
module.exports = function(app) {
    router.get('/', function(req, res) {
        res.render('signup', {});
    });

    router.post('/', function(req, res) {
        var name = req.body.username;
        var email = req.body.email;
        var password = req.body.password;
        var level = 3;
        var invite = null;
        var user = new app.User(name, email, password, level, invite);
        user.insert().success(function() {
            res.end('user added.');
        });
    });

    return router;
};
