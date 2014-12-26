#!/usr/bin/env bash

# This is the script that prepares the Python application to be run.
#
# Under Heroku this would be triggered from the Heroku post_compile hook.
# As Heroku does all the preparation of the image, only a build hook
# to be run after all the packages have been installed can be provided.
# If if it was necessary to run actions prior to pip being run to install
# packages, then you would need to define a pre_compile hook for Heroku.

# Ensure that any failure within this script or a user provided script
# causes this script to fail immediately. This eliminates the need to
# check individual statuses for anything which is run and prematurely
# exit. Note that the feature of bash to exit in this way isn't
# foolproof. Ensure that you heed any advice in:
#
#   http://mywiki.wooledge.org/BashFAQ/105
#   http://fvue.nl/wiki/Bash:_Error_handling
#
# and use best practices to ensure that failures are always detected.
# Any user supplied scripts should also use this failure mode.

set -eo pipefail

# Mark what runtime this is.

WHISKEY_RUNTIME=heroku
export WHISKEY_RUNTIME

# Set up the home directory for the application.

WHISKEY_HOMEDIR=/app
export WHISKEY_HOMEDIR

# Set up the bin directory where our scripts will be.

WHISKEY_BINDIR=/app/.heroku/python/bin
export WHISKEY_BINDIR

# Make sure we are in the correct working directory for the application.

cd $WHISKEY_HOMEDIR

# Copy the Apache executables into the Python directory so they can
# be found without working out how to override the PATH.

cp $WHISKEY_HOMEDIR/.whiskey/apache/bin/apxs $WHISKEY_BINDIR/apxs
cp $WHISKEY_HOMEDIR/.whiskey/apache/bin/httpd $WHISKEY_BINDIR/httpd
cp $WHISKEY_HOMEDIR/.whiskey/apache/bin/rotatelogs $WHISKEY_BINDIR/rotatelogs
cp $WHISKEY_HOMEDIR/.whiskey/apache/bin/ab $WHISKEY_BINDIR/ab

# Copy the mod_wsgi Heroku scripts into the Python bin directory as we
# can't make Heroku search our own directory for executables.

cp .whiskey/scripts/mod_wsgi-heroku-start $WHISKEY_BINDIR
cp .whiskey/scripts/mod_wsgi-heroku-shell $WHISKEY_BINDIR

# Build and install mod_wsgi. Heroku will have already run pip on any
# 'requirements.txt' file so we need to just ensure that the version of
# mod_wsgi we want will be installed.

$WHISKEY_BINDIR/pip install -U \
        https://github.com/GrahamDumpleton/mod_wsgi/archive/develop.zip

# Create the '.whiskey/user_vars' directory for storage of user defined
# environment variables if it doesn't already exist. These can be
# created by the user from any hook script. The name of the file
# corresponds to the name of the environment variable and the contents
# of the file the value to set the environment variable to.

mkdir -p .whiskey/user_vars

# Run any user supplied script to run after installing any application
# dependencies. This is to allow any application specific setup scripts
# to be run, such as 'collectstatic' for a Django web application. The
# script must be executable in order to be run.

if [ -x .whiskey/action_hooks/build ]; then
    echo " -----> Running .whiskey/action_hooks/build"
    .whiskey/action_hooks/build
fi
