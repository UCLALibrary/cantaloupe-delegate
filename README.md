# cantaloupe-delegate &nbsp;[![Build Status](https://travis-ci.org/UCLALibrary/cantaloupe-delegate.svg?branch=master)](https://travis-ci.org/UCLALibrary/cantaloupe-delegate)

A delegate script for the Cantaloupe IIIF server that takes a Hyrax file ID returns a Fedora URL. 

### Running tests

The Cantaloupe delegate uses JRuby so tests (the default rake task) should be run with it:

    jruby -S rake

### Running Cantaloupe

While not needed to run the test, to start Cantaloupe with the required delegate environmental variables:

    FEDORA_URL="http://localhost:8984/fcrepo/rest" \
      FEDORA_BASE_PATH="/prod" \
      java -Dcantaloupe.config=cantaloupe.properties \
      -Xmx2g -jar cantaloupe-4.0.2.war
