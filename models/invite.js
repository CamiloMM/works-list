var mongoose = require('mongoose');
var Schema   = mongoose.Schema;
var ObjectId = Schema.Types.ObjectId;

var inviteSchema = new Schema({
    inviter     : {type: ObjectId, ref: 'User', default: null},
    code        : String, // random, long string. This has to be provided by the invited.
    level       : Number, // invited user level. must be lower or equal to inviter's.
    used        : Boolean, // invites can only be used once.
    description : String, // to be seen only by the inviter.
});

var Invite = mongoose.model('Invite', userSchema);

module.exports = Invite;
