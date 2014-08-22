var express  = require('express');
var router   = express.Router();
var passport = require('passport');

router.get('/login', function(req, res) {
    res.render('login', {});
});

router.post('/login', passport.authenticate('local', {
    successRedirect: '/',
    failureRedirect: '/login',
    failureFlash: false
}));

module.exports = router;
