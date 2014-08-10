#!/bin/bash
# This is a camilo-style server script for the works-list website.
# The (really simple) API for it is described under "help", below.
# Note that we do not support starting the same server in two or more different ports.
# This is by design, because it would complicate things for no useful reason, and some
# servers might want to listen in two ports (like http+https).
# If the start method is called and the server is already started, it will re-start.
# If the stop method is called and the script is not running, it will just ignore it.
# If the restart method is called and the script is not running, it will start.
# If any method fails, it will return a non-zero status code.
# The info method gives you all the information you need about this server instance.
# Debug is similar to restart, but enables debugging options and stays foreground.

# One important thing to remember is that this must be runnable by Cron,
# and Cron has very limited environment variables (no $USER, $PATH is minimal...)
# So we're going to fix that now. Yes, we could just use absolute paths from now on,
# but that's very unpredictable; we'd have to take care when testing, etc. This is easier.
export PATH="$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games"
export USER="${USER:-$(whoami)}"

# This key must be unique by server. YOU MUST CHANGE IT if you re-use this server script.
# (This is used to identify the correct node process - it must not show up elsewhere)
export GUID='6827bfe4-c6fb-4eac-9da4-ff21767d9101'

# Port number. Expressjs uses this.
export PORT=${PORT-49445}

# Tells us if we're in debug mode.
debug=false

# Logfile.
logfile='server.log'

# This is the path to the server.js startup script. It can be relative.
script='bin/www'

# This is the script that is ran when the server is started.
run() {
    if $debug; then # Debug mode is meant for running in a console.
        node "$(absolute "$script")" "$GUID" | tee "$(absolute $logfile)"
    else
        node "$(absolute "$script")" "$GUID" 2> /dev/null > "$(absolute $logfile)" &
    fi
}

# Sanity check. The script above MUST exist in order to run this script.
sanity() {
    # Part of this was taken from absolute, below.
    old="$PWD"
    cd "$(base)"
    if ! cd "$(dirname "$script")" &> /dev/null; then
        echo "directory \"$(dirname "$script")\" not found!" 1>&2
        cd "$old"
        exit 44
    fi
    if [ ! -f "$PWD/$(basename "$script")" ]; then
        echo "file \"$PWD/$(basename "$script")\" not found!" 1>&2
        cd "$old"
        exit 44
    fi
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

# Normalize the script's path (the variable above).
# What this does is give you the absolute path to the script.
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

# Gets the Process ID of the node instance launched by us.
# If it returns an empty string, then no instance is running.
process() {
    # Options for ps - the windows build requires -W, the unix one does not ignore it.
    if windows; then opts='-W aux'; else opts='aux'; fi
    # The reason we're using a herestring instead of piping is because this way,
    # grep won't show up in the process list when ps is invoked.
    grep -F "$GUID" <<< "$(ps $opts)" | tr -s ' ' | cut -f 2 -d ' '
}

# Returns a value indicanting whether or not the node script is running.
running() { [[ -n "$(process)" ]]; }

# Show help.
help() {
    echo "Usage: $0 <start|stop|restart|debug|info>"
    echo "Read this script's comments for more."
}

# Start the server.
start() {
    if running; then
        restart
    else
        run
        sleep 1 # Give it time to start up in the background.
        running
    fi
}

# Stop the server.
# If we can't manage to stop it, return false.
stop() {
    retries=5
    if running; then
        if ! kill -s SIGINT "$(process)" &> /dev/null; then
            # We didn't manage to terminate the process via SIGINT
            if ((retries-- != 0)); then
                # Try again in one second.
                sleep 1
                stop
            else
                # After 5 attempts in 5 seconds, just go for SIGKILL.
                kill -s SIGKILL "$(process)" &> /dev/null
            fi
        fi
    fi
}

# Restart the server.
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

# (Re)start the server in a debugging mode.
debug() {
    export DEBUG=works-list
    debug=true
    restart
}

# Info about running script.
info() {
    echo "GUID:    $GUID"
    echo "script:  $(absolute "$script")"
    echo "running: $(running && echo yes"$($debug && echo , debugging $DEBUG)" || echo no)"
}

# HTTP 767
error() {
    echo "You are drunk. Avoid driving and/or having sex with the blurry people."
    exit 51
}

sanity # Check that blood is not falling down the walls.
trap stop EXIT # Exit gracefully.

case "$1" in
    -h|--help|help) help ;;
    start|stop|restart|info|debug) $1 ;;
    *) error ;;
esac
