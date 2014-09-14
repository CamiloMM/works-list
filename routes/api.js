var express  = require('express');
var router   = express.Router();
var mongoose = require('mongoose');
var User     = mongoose.model('User');

router.post('/api/validate/user', function(req, res) {
    // Pattern check.
    if (! /^[-_0-9a-zA-Z]{3,20}$/.test(req.body.name)) {
        res.json({valid: false, reason: 'Username invalid.'});
    } else {
        // Database check.
        User.findOne({name: req.body.name}, function(err, user) {
            var exists = !err && user;
            var response = {valid: !exists};
            if (exists) response.reason = 'Username unavailable.'
            res.json(response);
        });
    }
});

module.exports = router;
