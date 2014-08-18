var express = require('express');
var router  = express.Router();
var User    = mongoose.model('User');
var Invite  = mongoose.model('Invite');

router.get('/', function(req, res) {
    res.render('signup', {});
});

router.post('/', function(req, res) {
    var invite = req.body.invite;
    var username = req.body.username.toString().trim();

    // Check if the username is valid.
    if (! /^[-_0-9a-zA-Z ]{3,20}$/.test(username)) return fail('invalid username');

    // Check if the invite provided is an admin-level invite.
    if (invite === req.app.config.adminInvite) {
        createUser(null, 1);
    } else {
        // Check if the invite is valid.
        Invite.findOne({code: invite}, function(err, invite) {
            if (err) return fail(err.message);
            if (invite) {
                // The invite is valid. Check if there's no user with that name.
                User.findOne({name: username}, function(err, user) {
                    if (err) return fail(err.message);
                    if (!user) {
                        // There's no user with that name. Great!
                        createUser(invite.code, invite.level);
                    } else {
                        fail('another user has that name already');
                    }
                });
            } else {
                fail('invalid invite');
            }
        });
    }

    // This gets called if we're ready to create the user.
    function createUser(invite, level) {
        var user = new User({
            name:     username,
            email:    req.body.email || null,
            password: req.body.password,
            level:    level,
            invite:   invite
        });

        user.save(function() {
            res.send('User created! Most impressive.');
        });
    }

    // This gets called if we can't create the user.
    function fail(reason) {
        res.send(400, 'Could not create user: ' + (reason || 'unknown reason') + '.');
    }
});

return router;
