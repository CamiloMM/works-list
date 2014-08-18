var express = require('express');
var router  = express.Router();
var User    = mongoose.model('User');

/* GET users listing. */
router.get('/', function(req, res) {
    User.find(function(err, users) {
        res.send(users);
    })
});

module.exports = router;
