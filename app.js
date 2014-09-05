var express      = require('express');
var path         = require('path');
var favicon      = require('serve-favicon');
var logger       = require('morgan');
var cookieParser = require('cookie-parser');
var bodyParser   = require('body-parser');
var ObjectId     = require('mongodb').ObjectID;
var mongoose     = require('mongoose');
var session      = require('express-session');
var MongoStore   = require('connect-mongo')(session);
var requireDir   = require('require-dir');

var app = express();
app.config = require('./config.json');
mongoose.connect(app.config.dbUrl, {user: app.config.dbUser, pass: app.config.dbPass});
app.db = mongoose.connection;
app.db.on('error', console.error.bind(console, 'connection error:'));
app.db.once('open', function callback () {

    requireDir('./models');

    app.passport = require('./app/passport');

    var sessionSettings = {
        // The cookie here is configured with maxAge of one year AND ONE MILLISECOND.
        // No, seriously, who was the genius that thought cookies age should be in ms??
        cookie: { path: '/', httpOnly: true, secure: false, maxAge: 31104000001 },
        secret: app.config.secret, // Make sure you edit this in your config.
        resave: true,
        saveUninitialized: true,
        store: new MongoStore({db: mongoose.connection.db})
    };

    // Make our app accessible to our router
    app.use(function(req, res, next) { req.app = app; next(); });

    // view engine setup
    app.set('views', path.join(__dirname, 'views'));
    app.set('view engine', 'jade');

    app.use(favicon(__dirname + '/public/favicon.ico'));
    app.use(logger('dev'));
    app.use(bodyParser.json());
    app.use(bodyParser.urlencoded({extended: true}));
    app.use(cookieParser());
    app.use(express.static(path.join(__dirname, 'public')));
    app.use(session(sessionSettings));
    app.use(app.passport.initialize());
    app.use(app.passport.session());

    // Load local variables for templates.
    app.all('*', function(req, res, next) {
        res.locals.loggedIn = !!req.user;
        res.locals.currentUser = req.user;
        res.locals.get = function(name) { return app.get(name); };
        next();
    });

    var routes = requireDir('./routes');
    for (var i in routes) app.use('/', routes[i]);

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


});

require('./app/setup')(app);

module.exports = app;
