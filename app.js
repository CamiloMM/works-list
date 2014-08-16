var express      = require('express');
var path         = require('path');
var favicon      = require('static-favicon');
var logger       = require('morgan');
var cookieParser = require('cookie-parser');
var bodyParser   = require('body-parser');
var ObjectId     = require('mongodb').ObjectID;
var monk         = require('monk');
var session      = require('express-session');
var MongoStore   = require('connect-mongo')(session);

var app = express();
app.config = require('./config.json');
app.db = monk(app.config.dbUrl);
app.passport = require('./app/passport')(app.db.get('users'));
require('./app/models')(app);

var sessionSettings = {
    secret: app.config.secret, // Make sure you edit this in your config.
    resave: true,
    saveUninitialized: true,
    store: new MongoStore({url: app.config.dbUrl})
};

// Make our app accessible to our router
app.use(function(req, res, next) { req.app = app; next(); });

// view engine setup
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'jade');

app.use(favicon(__dirname + '/public/favicon.ico'));
app.use(logger('dev'));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded());
app.use(cookieParser());
app.use(session(sessionSettings));
app.use(app.passport.initialize());
app.use(app.passport.session());
app.use(express.static(path.join(__dirname, 'public')));

app.use('/'      , require('./routes/index'));
app.use('/users' , require('./routes/users'));
app.use('/login' , require('./routes/login')(app.passport));
app.use('/signup', require('./routes/signup')(app));

/// catch 404 and forward to error handler
app.use(function(req, res, next) {
    var err = new Error('Not Found');
    err.status = 404;
    next(err);
});

/// error handlers

// development error handler
// will print stacktrace
if (app.get('env') === 'development') {
    app.use(function(err, req, res, next) {
        res.status(err.status || 500);
        res.render('error', {
            message: err.message,
            error: err
        });
    });
}

// production error handler
// no stacktraces leaked to user
app.use(function(err, req, res, next) {
    res.status(err.status || 500);
    res.render('error', {
        message: err.message,
        error: {}
    });
});


module.exports = app;
