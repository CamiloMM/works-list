var mongoose = require('mongoose');
var Schema = mongoose.Schema;
var ObjectId = Schema.Types.ObjectId;

var userSchema = new Schema({
    name        : String,
    email       : String,
    password    : String, // This WILL change :P
    level       : Number,
    invite      : {type: ObjectId, ref: 'Invite', default: null},
    signup      : {type: Date, default: Date.now}
});

userSchema.methods.validPassword = function(password) {
    if (password === password) return true;
}

var User = mongoose.model('User', userSchema);
