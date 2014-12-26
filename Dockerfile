FROM ubuntu:14.04

RUN apt-get update && \
    apt-get install -y ca-certificates libssl1.0.0 curl gcc file \
        libc6-dev libssl-dev make xz-utils zlib1g-dev libsqlite3-dev \
        libpcre++0 libpcre++-dev python-pip python-virtualenv \
        --no-install-recommends

WORKDIR /app

RUN pip install zc.buildout boto

RUN buildout init

COPY buildout.cfg /app/

RUN buildout -v -v

RUN mkdir -p /app/.whiskey/scripts

COPY build.sh /app/.whiskey/scripts/mod_wsgi-heroku-build
COPY start.sh /app/.whiskey/scripts/mod_wsgi-heroku-start
COPY shell.sh /app/.whiskey/scripts/mod_wsgi-heroku-shell

RUN tar cvfz whiskey-heroku-cedar14-apache-2.4.10.tar.gz \
    .whiskey/apache .whiskey/apr-util .whiskey/apr .whiskey/scripts

RUN ls -las /app/whiskey-heroku-cedar14-apache-2.4.10.tar.gz

CMD s3put --access_key "$AWS_ACCESS_KEY_ID" \
          --secret_key "$AWS_SECRET_ACCESS_KEY" \
          --bucket $WHISKEY_BUCKET --prefix /app/ \
          /app/whiskey-heroku-cedar14-apache-2.4.10.tar.gz
