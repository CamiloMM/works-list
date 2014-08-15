var passport      = require('passport');
var LocalStrategy = require('passport-local').Strategy;

// Load this module and call it with the users collection to get a passport instance.
module.exports = function(users) {
    passport.use(new LocalStrategy(function(username, password, done) {
        users.findOne({username: username}, function(err, user) {
            if (err) { return done(err); }
            if (!user) {
                return done(null, false, { message: 'Incorrect username.' });
            }
            if (!user.validPassword(password)) {
                return done(null, false, { message: 'Incorrect password.' });
            }
            return done(null, user);
        });
    }));

    return passport;
};
