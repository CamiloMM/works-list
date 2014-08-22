var express  = require('express');
var router   = express.Router();
var mongoose = require('mongoose');
var User     = mongoose.model('User');

/* GET users listing. */
router.get('/users', function(req, res) {
    User.find(function(err, users) {
        res.send(users);
    })
});

module.exports = router;
