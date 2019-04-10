# cantaloupe-delegate &nbsp;[![Build Status](https://travis-ci.org/UCLALibrary/cantaloupe-delegate.svg?branch=master)](https://travis-ci.org/UCLALibrary/cantaloupe-delegate)

A delegate script for the Cantaloupe IIIF server that takes a Hyrax file ID returns a Fedora URL.

### Running tests

Cantaloupe uses JRuby to evaluate its delegate. I've found JRuby installed directly from [the source](https://www.jruby.org/) much more reliable than using what's available in the Ubuntu repositories. With that version of JRuby installed and configured, you can run:

    bundle install
    bundle exec rake

If you install JRuby in another way, you may need to run the following commands instead:

   jruby -S bundle install
   jruby -S bundle exec rake

### Running Cantaloupe

While not needed to run the test, to start Cantaloupe with the required delegate environmental variables:

    FEDORA_URL="http://localhost:8984/fcrepo/rest" \
      FEDORA_BASE_PATH="/prod" \
      java -Dcantaloupe.config=cantaloupe.properties \
      -Xmx2g -jar cantaloupe-4.0.2.war
