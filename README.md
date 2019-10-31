# cantaloupe-delegate &nbsp;[![Build Status](https://travis-ci.org/UCLALibrary/cantaloupe-delegate.svg?branch=master)](https://travis-ci.org/UCLALibrary/cantaloupe-delegate)

A delegate script for the Cantaloupe IIIF server that serves images from an S3 bucket.

### Running tests

Cantaloupe uses JRuby to evaluate its delegate. I've found JRuby installed directly from [the source](https://www.jruby.org/) much more reliable than using what's available in the Ubuntu repositories. With that version of JRuby installed and configured, you can run:

    bundle install
    bundle exec rake

If you install JRuby in another way, you may need to run the following commands instead:

   jruby -S bundle install
   jruby -S bundle exec rake

### Running Cantaloupe

While not needed to run the tests (those are self-contained), to start UCLA's [Cantaloupe container](https://cloud.docker.com/u/uclalibrary/repository/docker/uclalibrary/cantaloupe) with the required delegate environmental variables:

    docker run -d -p 8182:8182 \
      -e "CANTALOUPE_ENDPOINT_ADMIN_SECRET=secret" \
      -e "CANTALOUPE_ENDPOINT_ADMIN_ENABLED=true" \
      -e "CANTALOUPE_DELEGATE_SCRIPT_ENABLED=true" \
      -e "CANTALOUPE_DELEGATE_SCRIPT_PATHNAME=/usr/local/cantaloupe/delegates.rb" \
      -e "CANTALOUPE_DELEGATE_SCRIPT_CACHE_ENABLED=false" \
      -e "CANTALOUPE_SOURCE_DELEGATE=true" \
      -e "CANTALOUPE_S3SOURCE_LOOKUP_STRATEGY=BasicLookupStrategy" \
      -e "CANTALOUPE_S3SOURCE_BASICLOOKUPSTRATEGY_PATH_SUFFIX=.jpg" \
      -e "CANTALOUPE_S3SOURCE_BASICLOOKUPSTRATEGY_BUCKET_NAME=YOUR_BUCKET_NAME" \
      -e "CANTALOUPE_S3SOURCE_SECRET_KEY=YOUR_SECRET_KEY" \
      -e "CANTALOUPE_S3SOURCE_ACCESS_KEY_ID=YOUR_ACCESS_KEY" \
      -e "CANTALOUPE_S3SOURCE_ENDPOINT=s3.amazonaws.com" \
      -e "CANTALOUPE_LOG_APPLICATION_FILEAPPENDER_ENABLED=true" \
      -e "CIPHER_TEXT=Authenticated" \
      -e "CIPHER_KEY=ThisPasswordIsReallyHardToGuess!" \
      -e "CANTALOUPE_LOG_APPLICATION_FILEAPPENDER_PATHNAME=/var/log/cantaloupe/cantaloupe.log" \
      -e "DELEGATE_URL=https://raw.githubusercontent.com/UCLALibrary/cantaloupe-delegate/master/lib/delegates.rb" \
      --name melon -v /sinai:/imageroot uclalibrary/cantaloupe:4.1.4

The above configuration would be used to configure an S3 backend. A different configuration could be used to configure a file system backend.