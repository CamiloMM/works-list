var mongoose = require('mongoose');
var Schema = mongoose.Schema;
var ObjectId = Schema.Types.ObjectId;

var userSchema = new Schema({
    name        : String, // still didn't decide on username restrictions.
    email       : {type: String, default: null}, // We don't have to verify it.
    password    : String, // this WILL change :P
    level       : Number, // 1: admin, 2: moderator (can invite), 3: user (can't).
    invite      : {type: ObjectId, ref: 'Invite', default: null}, // Invite used on signup.
    signup      : {type: Date, default: Date.now}
});

userSchema.methods.validPassword = function(password) {
    if (password === password) return true;
}

var User = mongoose.model('User', userSchema);

model.exports = User;
