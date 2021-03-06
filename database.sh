#!/bin/bash
# This is a camilo-style server script for the works-list database.
# It is a companion to the server.sh script you'll find next to it.
# Read that for guidance, as this script is merely a mirror that manages the db.
# Also: we could have made this into a function of server.sh. But what if we
# ever want to run the db independently of the server? Or restart just it?

export PATH="$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games"
export USER="${USER:-$(whoami)}"

# Port number to use with the database.
port=50534

# Tells us if we're in debug mode.
debug=false

# Logfile.
logfile='database.log'

# This is the path to the database's data directory. It can be relative.
storage='data'

# Temporary storage for reporting process ID.
pid=-1

# There's an extra flag for internal use only: database.sh start fast
# (it tells us to skip the DB auth check).
if [[ "$2" == fast ]]; then fast=true; else fast=false; fi

# This is the function that is ran when the database is started.
run() {
    stdOpts="--auth --journal --smallfiles --port $port"
    if $debug; then
        # Debug mode is meant for running in a console. Also, it allows you to
        # connect to the database remotely for whatever reason you need.
        mongod $stdOpts --dbpath "$(absolute "$storage")"
    else
        mongod $stdOpts --bind_ip 127.0.0.1 --dbpath "$(absolute "$storage")" \
        --logpath "$(absolute "$logfile")" --logappend &> /dev/null &
    fi
}

# This function is run in preparation to starting the database. It checks for credentials,
# and creates users if the database does not have them. If the setup cannot be completed,
# we will tell it to the user and exit.
setup() {
    user="$(config dbUser)"
    pass="$(config dbPass)"
    if [[ -z "$checking" ]]; then echo 'Checking db auth credentials...'; checking=true; fi
    oldDebug=$debug # Don't want edge cases.
    debug=false
    if ! running; then run; sleep 2; fi # I'm giving it a bit of time to be on the safe side.
    if credentials works-list "$user" "$pass"; then
        # This is the normal working condition. Credentials are valid.
        # However, if we can also connect without credentials, that's such a huge
        # hole in security that it warrants telling the user and exiting anyway.
        if credentials; then
            echo "There's a glaring hole in your security, because we seemingly" 1>&2
            echo 'can connect to the database with or without proper credentials.' 1>&2
            echo 'You should fix this ASAP. Quitting now.'
            stop &> /dev/null
            exit 1
        else
            # If we got here, everything's good to go. Clean up.
            stop &> /dev/null
            debug=$oldDebug
            return 0
        fi
    elif credentials admin admin "$pass"; then
        # We now should create a regular database user.
        echo 'Creating db user...'
        js='use works-list
            eval("var config = " + cat("config.json") + ";");
            var role = {role: "dbOwner", db: "works-list"};
            db.createUser({user: config.dbUser, pwd: config.dbPass, roles: [role]});
            exit'
        execute admin admin "$pass" "$js" || echo 'Could not create db user!' 1>&2
        setup # Continue with setup.
    elif credentials admin; then
        # We should first set up an admin account. We'll use the same pass as the
        # regular user. For the purposes of this application, that's totally fine.
        echo 'Creating db admin...'
        js='use admin
            eval("var config = " + cat("config.json") + ";");
            var role = {role: "userAdminAnyDatabase", db: "admin"};
            db.createUser({user: "admin", pwd:config.dbPass, roles: [role]});
            exit'
        execute admin "$js" || echo 'Could not create db admin!' 1>&2
        setup # Continue with setup.
    else
        echo 'The credentials specified in config.json are invalid, and I cannot seem' 1>&2
        echo 'to be able to use the localhost exception to create users myself.' 1>&2
        echo 'Please fix this issue, and restart. Exiting now.' 1>&2
        stop &> /dev/null
        exit 1
    fi
}

# This function gets a property from the config file. If the property does not exist
# or the config file is not found or has bad syntax, the script will exit with an error.
config() {
    old="$PWD"
    cd "$(base)"
    if ! node -e "console.log(require('./config.json').$1 || OHNOES)" 2> /dev/null; then
        echo "We could not get property \"$1\" from the config file." 1>&2
        # We can be helpful and try to tell the user the reason for this.
        which node > /dev/null || echo 'Node executable unavailable!' 1>&2
        [[ -f config.json ]] || echo "config.json not found in \"$PWD\""'!' 1>&2
        echo 'We will now halt any operations underway.' 1>&2
        cd "$old"
        exit 1
    fi
    cd "$old"
}

# Checks that the given db/user/pass credentials work.
# If you don't pass it credentials, it checks whether localhost exception is in place.
credentials() {
    if [[ -n "$3" ]]; then
        mongo -u "$2" -p "$3" "127.0.0.1:50534/$1" <<< '' &> /dev/null
    else
        mongo "127.0.0.1:50534/$1" <<< '' &> /dev/null
    fi
}

# Executes commands on the database. The commands are ran in the current directory.
# If three parameters are given, run as `execute db user pass command`.
# If one parameter is given, run as `execute db command` without authentication.
# The output is excluded, but the return code is mongo's.
execute() {
    old="$PWD"
    cd "$(base)"
    if [[ -z "$3$4" ]]; then
        mongo "127.0.0.1:50534/$1" <<< "$2" &> /dev/null
        code=$?
    else
        mongo -u "$2" -p "$3" "127.0.0.1:50534/$1" <<< "$4" &> /dev/null
        code=$?
    fi
    cd "$old"
    return $code
}

# Sanity check. Mongo tools MUST be available.
sanity() {
    # Part of this was taken from absolute, below.
    old="$PWD"
    cd "$(base)"
    if [ ! -f "$(which mongod)" ]; then
        echo "Mongo tools not found! Make sure it is installed and available to PATH." 1>&2
        cd "$old"
        exit 44
    fi
    mkdir -p "$storage" # "Make sure" the data directory is present.
    cd "$old"
}

# Get the running script's location (parent directory), in a cross-platform way.
base() {
    if windows; then
        dirname "$(echo "${BASH_SOURCE[0]}" | tr '\\' /)"
    else
        dirname "${BASH_SOURCE[0]}"
    fi
}

# Are we running on Windows?
windows() { [[ -n "$WINDIR" ]]; }

# Normalize a relative path.
# This is more complicated than it seems, 'cause we can't rely on realpath or readlink.
# (Call it with the path to normalize as the argument, like `absolute "$script"`.)
absolute() {
    # It took me way too much time to accept that this is the simplest solution.
    old="$PWD"
    cd "$(base)"
    cd "$(dirname "$1")"
    echo "$PWD/$(basename "$1")"
    cd "$old"
}

# Gets the Process ID of the database instance launched by us.
# If it returns an empty string, then no instance is running.
process() {
    if windows; then
        # The reason we're using a herestring instead of piping is because this way,
        # grep won't show up in the process list when wmic or ps is invoked.
        processes="$(WMIC path win32_process get Commandline,Processid | tr -s ' ')"
        grep -F "mongod" <<< "$processes" | grep -F "$port" | sed 's/\s*$//;s/.* //'
    else
        grep -F "mongod" <<< "$(ps aux)" | grep -F "$port" | tr -s ' ' | cut -f 2 -d ' '
    fi
}

# Returns a value indicanting whether or not the node script is running.
running() { pid=$(process); [[ -n "$pid" ]]; }

# Show help.
help() {
    echo "Usage: $0 <start|stop|restart|debug|info|upgrade|repair>"
    echo "Read this script's comments for more."
}

# Start the database.
# If we can't manage to start it, return false.
start() {
    if ! running; then
        if ! $fast; then setup; fi # Don't perform setup in fast mode.
        run
        sleep 1 # Give it time to start up in the background.
        running && started
    fi
}

# Stop the database.
# If we can't manage to stop it, return false.
stop() {
    # Windows needs special love, because of the trisomy 21 developer team.
    if windows; then prefix='/bin/'; flag='-f'; fi
    retries=${retries:-5}
    if running; then
        if ${prefix}kill $flag -s SIGINT "$(process)" &> /dev/null; then
            stopped
        else
            # We didn't manage to terminate the process via SIGINT
            if ((retries-- != 0)); then
                # Try again in one second.
                sleep 1
                stop
            else
                # After 5 attempts in 5 seconds, just go for SIGKILL.
                if kill -s SIGKILL "$(process)" &> /dev/null; then
                    stopped
                fi
            fi
        fi
    fi
}

# Restart the database.
# If we can't manage to stop it, or start after stopping, return false.
restart() {
    if running; then
        # Restarting the DB also enables fast mode.
        fast=true
        if stop; then
            start
        else
            false
        fi
    else
        start
    fi
}

# What to do when successfully started.
started() {
    echo "Database server on port $port started (process ID $pid)."
}

# What to do when successfully stopped.
stopped() {
    echo "Database server on port $port stopped (process ID $pid)."
}

# (Re)start the database in a debugging mode.
debug() {
    debug=true
    restart
}

# Info about running script.
info() {
    echo "port:    $port"
    echo "data:    $(absolute "$storage")"
    echo "running: $(running && echo yes, $($debug && echo debugging with) process ID $pid || echo no)"
}

# HTTP 767
error() {
    echo "You are drunk. Avoid driving and/or having sex with the blurry people."
    exit 51
}

# Asks MongoDB to upgrade the database.
upgrade() {
    stop
    mongod --upgrade --dbpath "$(absolute "$storage")"
    start
}

# Asks MongoDB to repair the database.
repair() {
    stop
    mongod --repair --dbpath "$(absolute "$storage")"
    start
}

sanity # Check that blood is not falling down the walls.
trap stop SIGHUP SIGINT SIGTERM # Exit gracefully.

case "$1" in
    -h|--help|help) help ;;
    start|stop|restart|info|debug|upgrade|repair) $1 ;;
    *) error ;;
esac
