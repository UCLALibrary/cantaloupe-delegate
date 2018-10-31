# cantaloupe-delegate

A delegate script for the Cantaloupe IIIF server.

### Running tests

The Cantaloupe delegate uses JRuby so tests should be run with it:

    jruby -S rspec spec/http_resolver_spec.rb

### Running Cantaloupe

There are three environmental settings that the delegate needs. The
can be supplied on the command line:

    FEDORA_URL="http://localhost:8984/fcrepo/rest" \
      FEDORA_BASE_PATH="/prod" \
      java -Dcantaloupe.config=cantaloupe.properties \
      -Xmx2g -jar cantaloupe-4.0.2.war
