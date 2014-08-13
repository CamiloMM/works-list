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

# This is the script that is ran when the database is started.
run() {
    if $debug; then # Debug mode is meant for running in a console.
        mongod --journal --smallfiles --port $port --dbpath "$(absolute "$storage")"
    else
        mongod --journal --smallfiles --port $port --dbpath "$(absolute "$storage")" \
        --logpath "$(absolute "$logfile")" --logappend &> /dev/null &
    fi
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
    echo "script:  $(absolute "$script")"
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
