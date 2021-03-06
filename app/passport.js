var passport      = require('passport');
var LocalStrategy = require('passport-local').Strategy;
var mongoose      = require('mongoose');
var User          = mongoose.model('User');

passport.use(new LocalStrategy(function(username, password, done) {
    User.findOne({name: username}, function(err, user) {
        if (err) return done(err);
        if (!user) {
            return done(null, false, { message: 'Incorrect username.' });
        }
        user.validatePassword(password, function(err, valid) {
            if (err) return done(err);
            if (!valid) return done(null, false, { message: 'Incorrect password.' });
            done(null, user);
        })
    });
}));

passport.serializeUser(function(user, done) {
    done(null, user.id);
});

passport.deserializeUser(function(id, done) {
    User.findById(id, function(err, user) {
        done(err, user);
    });
});

module.exports = passport;
