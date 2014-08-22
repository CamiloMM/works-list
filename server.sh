#!/bin/bash
# This is a camilo-style server script for the works-list website.
# The (really simple) API for it is described under "help", below.
# Note that we do not support starting the same server in two or more different ports.
# This is by design, because it would complicate things for no useful reason, and some
# servers might want to listen in two ports (like http+https).
# If the start method is called and the server is already started, it will NOT re-start.
# If the stop method is called and the script is not running, it will just ignore it.
# If the restart method is called and the script is not running, it will start.
# If any method fails, it will return a non-zero status code.
# The info method gives you all the information you need about this server instance.
# Debug is similar to restart, but enables debugging options and stays foreground.
# The update method is, seemingly, working just fine for me, but I believe I'm
# relying on undefined behavior here. So if it fails for you, do that manually.

# One important thing to remember is that this must be runnable by Cron,
# and Cron has very limited environment variables (no $USER, $PATH is minimal...)
# So we're going to fix that now. Yes, we could just use absolute paths from now on,
# but that's very unpredictable; we'd have to take care when testing, etc. This is easier.
export PATH="$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games"
export USER="${USER:-$(whoami)}"

# This key must be unique by server. YOU MUST CHANGE IT if you re-use this server script.
# (This is used to identify the correct node process - it must not show up elsewhere)
GUID='6827bfe4-c6fb-4eac-9da4-ff21767d9101'

# Port number. Expressjs uses this.
export PORT=49445

# Tells us if we're in debug mode.
debug=false

# Logfile.
logfile='server.log'

# This is the path to the server.js startup script. It can be relative.
script='bin/www'

# Git URL for our repository; we use this for the self-update.
origin='git://github.com/CamiloMM/works-list.git'

# Temporary storage for reporting process ID.
pid=-1

# This is the script that is ran when the server is started.
run() {
    if $debug; then # Debug mode is meant for running in a console.
        node "$(absolute "$script")" "$GUID"
    else
        node "$(absolute "$script")" "$GUID" 2>&1 | \
        sed -r 's:(\\x1b|\x1b)\[[0-9;]*m::g' > "$(absolute $logfile)" &
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

# Gets the Process ID of the node instance launched by us.
# If it returns an empty string, then no instance is running.
process() {
    if windows; then
        # The reason we're using a herestring instead of piping is because this way,
        # grep won't show up in the process list when wmic or ps is invoked.
        processes="$(WMIC path win32_process get Commandline,Processid | tr -s ' ')"
        grep -F "$GUID" <<< "$processes" | sed 's/\s*$//;s/.* //'
    else
        grep -F "$GUID" <<< "$(ps aux)" | tr -s ' ' | cut -f 2 -d ' '
    fi
}

# Returns a value indicanting whether or not the node script is running.
running() { pid=$(process); [[ -n "$pid" ]]; }

# Show help.
help() {
    echo "Usage: $0 <start|stop|restart|debug|info|update|modules>"
    echo "Read this script's comments for more."
}

# Start the server.
# If we can't manage to start it, return false.
start() {
    # Make sure we have all packages installed.
    modules
    "$(absolute database.sh)" start
    if ! running; then
        run
        sleep 1 # Give it time to start up in the background.
        running && started
    fi
}

# Stop the server.
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

# What to do when successfully started.
started() {
    echo "Node server $GUID started on port $PORT (process ID $pid)."
}

# What to do when successfully stopped.
stopped() {
    echo "Node server $GUID stopped on port $PORT (process ID $pid)."
    "$(absolute database.sh)" stop
}

# (Re)start the server in a debugging mode.
debug() {
    # By default, ignore most of the noise.
    export DEBUG="${DEBUG:-*,-express:*,-send,-express-session}"
    debug=true
    echo "Starting node server $GUID in debug mode on port $PORT."
    restart
}

# Info about running script.
info() {
    echo "guid:    $GUID"
    echo "port:    $PORT"
    echo "script:  $(absolute "$script")"
    echo "running: $(running && echo yes, "$($debug && echo debugging "$DEBUG" with' ')"process ID $pid || echo no)"
}

# This method works, though I was surprised that it did, even when replacing ITSELF.
# But in other words, if the update fails, just get new code from GitHub manually.
update() {
    # Check if we're running. If we are, we'll re-start later.
    if running; then restart=true; else restart=false; fi
    # Stop everything for the update.
    stop
    # We're going to create a subshell. This should protect our flow.
    (
        # Also, I'm new to git; So this may not be the best way, but it does work.
        git init -q
        [[ -z "$(git remote show)" ]] && git remote add origin "$origin"
        git reset --hard -q && git pull origin master
        code=$?
        $restart && "${BASH_SOURCE[0]}" start
        # In no circumstance more code should be ran after this point.
        exit $code
    )
}

# This method makes sure that the node_modules are built for the current platform.
# Also, as a rule of thumb. DO NOT RUN NPM INSTALL. This will delete a directory if
# it finds one, because it's meant to be a symlink. Ancient filesystems such as
# FAT are not supported, neither OSes that don't know what a symlink is (WinXP).
modules() {
    # Just to make sure that everything works as intended, let's be on the right dir.
    old="$PWD"
    cd "$(base)"
    target="deps/native/node_modules-$(uname -s)-$(uname -m)-node-$(node -v)"
    # Check if something exists already.
    # Note that we need to perform the link check here too, because *long bug story*.
    if [[ -e node_modules ]] || link node_modules; then
        # Check if it's a link. If it's a link, we'll just remove it.
        # If it's not, we'll also do that but scold the user, too.
        if link node_modules; then
            rmlink node_modules
        else
            echo 'Warning: node_modules was found, and it was not a symlink.' 1>&2
            echo 'Usually, this means that you ran npm install by yourself.' 1>&2
            echo 'This script handles that, and will delete your node_modules.' 1>&2
            rm -rf node_modules
        fi
    fi
    # Now node_modules is not supposed to exist.
    if [[ -e node_modules ]]; then
        # If it still exists, it means we couldn't remove it. Warn the user and return.
        echo 'We could not remove node_modules. Something is wrong here!' 1>&2
        echo '(we will not continue in this case.)' 1>&2
        cd "$old"
        exit 1
    fi
    # Now that we know node_modules doesn't exist, check if our target exists.
    if [[ ! -d "$target" ]]; then
        mkdir "$target" # Note that if it was a file, the user was just asking for it.
    fi
    # If we couldn't create it, error out.
    if [[ ! -d "$target" ]]; then
        echo 'We could not create a native install dir. Something is wrong here!' 1>&2
        echo '(we will not continue in this case.)' 1>&2
        cd "$old"
        exit 1
    fi
    link node_modules "$target"
    # If node_modules cannot be found, error out.
    if [[ ! -e node_modules ]]; then
        echo 'We could not create a symlink. Something is wrong here!' 1>&2
        echo 'In particular, check if you are not in WinXP or a FAT partition.' 1>&2
        echo '(we will not continue in this case.)' 1>&2
        cd "$old"
        exit 1
    fi
    # Now, if our native directory didn't exist before, we must run npm install.
    if $debug; then
        npm install
    else
        # If not on debug mode, hide most of it. Important things will still show up.
        echo "checking and installing any missing or outdated packages..." 1>&2
        npm install > /dev/null
    fi
    # Go back to where we belong.
    cd "$old"
}

# Cross-platform symlink function. With one parameter, it will check
# whether the parameter is a symlink. With two parameters, it will create
# a symlink to a file or directory, with syntax: link $linkname $target
link() {
    if [[ -z "$2" ]]; then
        # Link-checking mode.
        if windows; then
            fsutil reparsepoint query "$1" > /dev/null
        else
            [[ -h "$1" ]]
        fi
    else
        # Link-creation mode.
        if windows; then
            # Windows needs to be told if it's a directory or not. Infer that.
            # Also: note that we convert `/` to `\`. In this case it's necessary.
            if [[ -d "$2" ]]; then
                cmd <<< "mklink /D \"$1\" \"${2//\//\\}\"" > /dev/null
            else
                cmd <<< "mklink \"$1\" \"${2//\//\\}\"" > /dev/null
            fi
        else
            # You know what? I think ln's parameters are backwards.
            ln -s "$2" "$1"
        fi
    fi
}

# Remove a link, cross-platform.
rmlink() {
    if windows; then
        # Again, Windows needs to be told if it's a file or directory.
        # But first, one must remove the reparsepoint, because *long bug story*
        fsutil reparsepoint delete "$1"
        if [[ -d "$1" ]]; then
            rmdir "$1";
        else
            rm "$1"
        fi
    else
        rm "$1"
    fi
}

# HTTP 767
error() {
    echo "You are drunk. Avoid driving and/or having sex with the blurry people."
    exit 51
}

sanity # Check that blood is not falling down the walls.
trap stop SIGHUP SIGINT SIGTERM # Exit gracefully.

case "$1" in
    -h|--help|help) help ;;
    start|stop|restart|info|debug|update|modules) $1 ;;
    *) error ;;
esac
