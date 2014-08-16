// User model. See app/models.

module.exports = function(app) {
    // Users collection.
    var users = app.db.get('users');

    // This is a regular javascript constructor too.
    // After setting up a new user, you must .insert() it to have it in the db.
    function User(name, email, password, level, invite) {
        this.name     = name;
        this.email    = email;
        this.password = password; // This will be changed.
        this.level    = level;
        this.invite   = invite;
        this.creation = new Date();
    }

    // This will throw errors if it can't insert, such as if the user exists.
    // Returns a promise.
    User.prototype.insert = function() {
        return users.findOne({name: this.name})
        .success(function (doc) {
            if (!doc) return true;
            throw new Error('user already exists');
        })
        .success(users.insert(this.serialize()))
        .success(callback)
    };

    // Serializes the user into an object.
    User.prototype.serialize = function() {
        return {
            name    : this.name,
            email   : this.email,
            password: this.password,
            level   : this.level,
            invite  : this.invite,
            creation: +this.creation
        };
    };

    // Deserializes an user from an object.
    User.deserialize = function(obj) {
        var user = new User(obj.name, obj.email, obj.password, obj.level, obj.invite);
        user.creation = new Date(obj.creation);
        return user;
    };

    return User;
};
