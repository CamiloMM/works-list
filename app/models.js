// This module handles model loading.
// Yes, I know we don't NEED models in a NoSQL database.
// But I would really like to have proper classes and such.

module.exports = function(app) {
    app.User = require('../models/user')(app);
}
