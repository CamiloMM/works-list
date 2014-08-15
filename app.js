var express      = require('express');
var path         = require('path');
var favicon      = require('static-favicon');
var logger       = require('morgan');
var cookieParser = require('cookie-parser');
var bodyParser   = require('body-parser');
var mongo        = require('mongodb');
var monk         = require('monk');
var session      = require('express-session');
var MongoStore   = require('connect-mongo')(session);

var config = require('./config.json');
var db = monk(config.dbUrl);
var passport = require('./app/passport')(db.get('users'));
var app = express();

var sessionSettings = {
    secret: config.secret, // Make sure you edit this in your config.
    resave: true,
    saveUninitialized: true,
    store: new MongoStore({url: config.dbUrl})
};

// Make our db accessible to our router
app.use(function(req, res, next) {
    req.db = db;
    next();
});

// view engine setup
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'jade');

app.use(favicon(__dirname + '/public/favicon.ico'));
app.use(logger('dev'));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded());
app.use(cookieParser());
app.use(session(sessionSettings));
app.use(passport.initialize());
app.use(passport.session());
app.use(express.static(path.join(__dirname, 'public')));

app.use('/'     , require('./routes/index'));
app.use('/users', require('./routes/users'));
app.use('/login', require('./routes/login')(passport));

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
