var express = require('express');
var router = express.Router();

// Login page. Depends on a configured passport object.
module.exports = function(passport) {
    router.get('/', function(req, res) {
        res.render('login', {});
    });

    router.post('/', passport.authenticate('local', {
        successRedirect: '/',
        failureRedirect: '/login',
        failureFlash: false
    }));

    return router;
};
