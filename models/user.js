var mongoose = require('mongoose');
var Schema   = mongoose.Schema;
var ObjectId = Schema.Types.ObjectId;
var crypto   = require("crypto");

var userSchema = new Schema({
    name   : String, // still didn't decide on username restrictions.
    email  : {type: String, default: null}, // We don't have to verify it.
    md5    : String, // MD5 of the user's e-mail, mainly for gravatars.
    hash   : String, // a bcrypt hash of the password.
    level  : Number, // 1: admin, 2: moderator (can invite), 3: user (can't).
    invite : {type: ObjectId, ref: 'Invite', default: null}, // Invite used on signup.
    signup : {type: Date, default: Date.now}
});

userSchema.methods.validatePassword = function(password, callback) {
    bcrypt.compare(password, this.hash, function(err, validity) {
        callback(err, validity);
    });
};

// Generate a gravatar URL. Size is optional.
userSchema.methods.gravatar = function(size) {
    // Note that, supposedly, one would need to request from www.gravatar.com,
    // or even secure.gravatar.com for HTTPS, but this doesn't seem to be
    // actually necessary. HTTP or HTTPS load from this base URL just fine.
    var base = '//gravatar.com/avatar/';
    var params = [
        's=' + (size || 128),
        'd=' + 'mm', // "Mystery Man" default image
        'r=' + 'x' // "Oh my gosh, think of the children!!" - except, no.
    ];
    return base + this.md5 + '?' + params.join('&');
};

// Generate a Gravatar-compatible MD5.
userSchema.statics.md5 = function(email) {
    var hash = crypto.createHash("md5");
    hash.update(String(email).toLowerCase().trim());
    return hash.digest("hex");
};

var User = mongoose.model('User', userSchema);

module.exports = User;
