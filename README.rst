=================
MOD_WSGI (HEROKU)
=================

The ``mod_wsgi-heroku`` package is a companion package for Apache/mod_wsgi.
It provides a means of building Apache/mod_wsgi support via Docker which
can be posted up to S3 and then pulled down when deploying sites to
Heroku. This then permits the running of Apache/mod_wsgi on Heroku sites.

Building Apache/mod_wsgi
------------------------

Check out this repository from github and run within it::

    docker build -t mod_wsgi-heroku .

This will create a Docker image with a prebuilt installation of Apache
within it. It will also contain helper scripts to aid in deploying your
WSGI application to Heroku using ``mod_wsgi-express`` as the way of
launching Apache/mod_wsgi.

Once built you need to upload that prebuilt Apache installation up to an
S3 bucket you control. To do that run::

    docker run -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
               -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
               -e WHISKEY_BUCKET=YOUR-BUCKET-NAME mod_wsgi-heroku

This assumes you have your AWS access and secret key defined in environment
variables of the user you are running the command as.

You should also replace ``YOUR-BUCKET-NAME`` with the actual name of the S3
bucket you have and which you are going to use to hold the tar ball for the
prebuilt version of Apache.

Integrating with Heroku
-----------------------

In the git repository containing your WSGI application and which you intend
to push up to Heroku now make the following changes.

First create the file ``bin/post_compile`` containing::

    WHISKEY_BUCKET=${WHISKEY_BUCKET:-modwsgi.org}
    WHISKEY_PACKAGE=whiskey-heroku-cedar14-apache-2.4.10.tar.gz
    WHISKEY_HOMEDIR=/app

    URL=https://s3.amazonaws.com/$WHISKEY_BUCKET/$WHISKEY_PACKAGE

    curl -o $WHISKEY_HOMEDIR/$WHISKEY_PACKAGE $URL
    tar -C $WHISKEY_HOMEDIR -x -v -z -f $WHISKEY_HOMEDIR/$WHISKEY_PACKAGE
    rm -f $WHISKEY_HOMEDIR/$WHISKEY_PACKAGE

    $WHISKEY_HOMEDIR/.whiskey/scripts/mod_wsgi-heroku-build

Replace ``modwsgi.org`` with the name of the bucket to which you uploaded
the result of the build above.

If just wanting to experiment, you can use the default ``modwsgi.org``
versions. These are located in AWS US-East. If you are deploying to Heroku
running in a different region, you would be better off to build your own
and host your bucket in the same region as you are deploying. I also don't
guarantee the long term availability of the ``modwsgi.org`` images at this
point as I don't know what the S3 costs may end up being for hosting them
and having everyone use them.

The second step is to set the ``web`` command in the ``Procfile``. This
should be set to::

    web: mod_wsgi-heroku-start wsgi.py

where ``wsgi.py`` is the relative file system path to the WSGI script file
containing the WSGI application entry point.

For further details on other options for referring to a WSGI application see
the ``mod_wsgi-express`` documentation as any arguments after the command
``mod_wsgi-heroku-start`` are passed directly to ``mod_wsgi-express``.

Restrictions on Heroku
----------------------

For ``mod_wsgi-express`` to work on a target platform, that platform must
provide dynamically loadable, shared library variants, of the Python runtime
libraries.

At this time Heroku doesn't provide such shared libraries for all Python
runtimes they provide. The only runtime that it is known they currently
provide them for is Python 3.4.1. As a result, you must be using Python
3.4.1 and have set ``python-3.4.1`` in the ``runtime.txt`` file that
controls which Python runtime Heroku will use.

Comments from Heroku suggest that they may discontinue providing shared
libraries even for Python 3.4.1. If that is the case then it will be
impossible to use ``mod_wsgi-express`` at all on Heroku.

If you want to see continued support for ``mod_wsgi-express`` and the
addition of support for Python 2.7, then you will need to raise it directly
with Heroku.
