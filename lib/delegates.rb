# frozen_string_literal: true

##
# Ruby delegate script for Sinai Cantaloupe
#
# This script is based on the example delegate script from
# the Cantaloupe project, containing stubs and documentation for all
# available delegate methods. See the user manual for more information.
#
# The application will create an instance of this class early in the request
# cycle and dispose of it at the end of the request cycle. Instances don't need
# to be thread-safe, but sharing information across instances (requests)
# **does** need to be done thread-safely.
#
# This version of the script works with Cantaloupe version 4, and not earlier
# versions. It *might* work with Cantaloupe version 5, YMMV
#

require 'openssl'
require 'cgi'

# Cantaloupe CustomDelegate method for customized authentication, and more!
class CustomDelegate
  ##
  # Attribute for the request context, which is a hash containing information
  # about the current request.
  #
  # This attribute will be set by the server before any other methods are
  # called. Methods can access its keys like:
  #
  # ```
  # identifier = context['identifier']
  # ```
  #
  # The hash will contain the following keys in response to all requests:
  #
  # * `client_ip`        [String] Client IP address.
  # * `cookies`          [Hash<String,String>] Hash of cookie name-value pairs.
  # * `identifier`       [String] Image identifier.
  # * `request_headers`  [Hash<String,String>] Hash of header name-value pairs.
  # * `request_uri`      [String] URI requested by the client.
  # * `local_uri`        [String] URI seen by the application, which may be
  #                      different from `request_uri` when operating behind a
  #                      reverse-proxy server.
  # * `scale_constraint` [Array<Integer>] Two-element array with scale
  #                      constraint numerator at position 0 and denominator at
  #                      position 1.
  #
  # It will contain the following additional string keys in response to image
  # requests:
  #
  # * `full_size`      [Hash<String,Integer>] Hash with `width` and `height`
  #                    keys corresponding to the pixel dimensions of the
  #                    source image.
  # * `metadata`       [Hash<String,Object>] Embedded image metadata. Object
  #                    structure varies depending on the source image.
  #                    See the `metadata()` method.
  # * `operations`     [Array<Hash<String,Object>>] Array of operations in
  #                    order of application. Only operations that are not
  #                    no-ops will be included. Every hash contains a `class`
  #                    key corresponding to the operation class name, which
  #                    will be one of the `e.i.l.c.operation.Operation`
  #                    implementations.
  # * `output_format`  [String] Output format media (MIME) type.
  # * `resulting_size` [Hash<String,Integer>] Hash with `width` and `height`
  #                    keys corresponding to the pixel dimensions of the
  #                    resulting image after all operations have been applied.
  #
  # @return [Hash] Request context.
  #
  attr_accessor :context

  ##
  # Returns authorization status for the current request. Will be called upon
  # all requests to all public endpoints.
  #
  # Implementations should assume that the underlying resource is available,
  # and not try to check for it.
  #
  # Possible return values:
  #
  # 1. Boolean true/false, indicating whether the request is fully authorized
  #    or not. If false, the client will receive a 403 Forbidden response.
  # 2. Hash with a `status_code` key.
  #     a. If it corresponds to an integer from 200-299, the request is
  #        authorized.
  #     b. If it corresponds to an integer from 300-399:
  #         i. If the hash also contains a `location` key corresponding to a
  #            URI string, the request will be redirected to that URI using
  #            that code.
  #         ii. If the hash also contains `scale_numerator` and
  #            `scale_denominator` keys, the request will be
  #            redirected using that code to a virtual reduced-scale version of
  #            the source image.
  #     c. If it corresponds to 401, the hash must include a `challenge` key
  #        corresponding to a WWW-Authenticate header value.
  #
  # @param options [Hash] Empty hash.
  # @return [Boolean,Hash<String,Object>] See above.
  #
  def authorize(_options = {})
    # Fun, fun... our Cantaloupe docker container likes it one way, our dev machines another
    @cookies = context['cookies']
    @cookies = context[:cookies] if @cookies.nil?

    # Our important cookie names
    iv = 'initialization_vector'
    auth = 'sinai_authenticated'

    # Check whether we're authorized to view the requested item
    if image_request?
      @cookies.key?(iv) && @cookies.key?(auth) && auth_value.start_with?(ENV['CIPHER_TEXT'])
    else
      true
    end
  end

  # Check whether a request is an image or info.json request
  def image_request?
    !context['request_uri'].end_with?('.json')
  end

  # Check the authentication value in the expected auth cookie
  def auth_value
    cipher_text = @cookies['sinai_authenticated']
    decipher = OpenSSL::Cipher::AES256.new :CBC
    decipher.decrypt
    decipher.iv = @cookies['initialization_vector']
    decipher.key = ENV['CIPHER_KEY']
    auth_cookie = [cipher_text].pack('H*').unpack('C*').pack('c*')
    decipher.update(auth_cookie) + decipher.final
  end

  ##
  # Used to add additional keys to an information JSON response. See the
  # [Image API specification](http://iiif.io/api/image/2.1/#image-information).
  #
  # @param options [Hash] Empty hash.
  # @return [Hash] Hash that will be merged into an IIIF Image API 2.x
  #                information response. Return an empty hash to add nothing.
  #
  def extra_iiif_information_response_keys(_options = {})
    #     Example:
    #     {
    #         'attribution' =>  'Copyright My Great Organization. All rights '\
    #                           'reserved.',
    #         'license' =>  'http://example.org/license.html',
    #         'logo' =>  'http://example.org/logo.png',
    #         'service' => {
    #             '@context' => 'http://iiif.io/api/annex/services/physdim/1/context.json',
    #             'profile' => 'http://iiif.io/api/annex/services/physdim',
    #             'physicalScale' => 0.0025,
    #             'physicalUnits' => 'in'
    #         }
    #     }
    {}
  end

  ##
  # Tells the server which source to use for the given identifier.
  #
  # @param options [Hash] Empty hash.
  # @return [String] Source name.
  #
  def source(_options = {})
    'S3Source'
  end

  ##
  # N.B.: this method should not try to perform authorization. `authorize()`
  # should be used instead.
  #
  # @param options [Hash] Empty hash.
  # @return [String,nil] Blob key of the image corresponding to the given
  #                      identifier, or nil if not found.
  #
  def azurestoragesource_blob_key(options = {}); end

  ##
  # N.B.: this method should not try to perform authorization. `authorize()`
  # should be used instead.
  #
  # @param options [Hash] Empty hash.
  # @return [String,nil] Absolute pathname of the image corresponding to the
  #                      given identifier, or nil if not found.
  #
  def filesystemsource_pathname(options = {}); end

  ##
  # Returns one of the following:
  #
  # 1. String URI
  # 2. Hash with the following keys:
  #     * `uri` [String] (required)
  #     * `username` [String] For HTTP Basic authentication (optional).
  #     * `secret` [String] For HTTP Basic authentication (optional).
  #     * `headers` [Hash<String,String>] Hash of request headers (optional).
  # 3. nil if not found.
  #
  # N.B.: this method should not try to perform authorization. `authorize()`
  # should be used instead.
  #
  # @param options [Hash] Empty hash.
  # @return See above.
  #
  def httpsource_resource_info(options = {}); end

  ##
  # N.B.: this method should not try to perform authorization. `authorize()`
  # should be used instead.
  #
  # @param options [Hash] Empty hash.
  # @return [String] Identifier of the image corresponding to the given
  #                  identifier in the database.
  #
  def jdbcsource_database_identifier(options = {}); end

  ##
  # Returns either the media (MIME) type of an image, or an SQL statement that
  # can be used to retrieve it, if it is stored in the database. In the latter
  # case, the "SELECT" and "FROM" clauses should be in uppercase in order to
  # be autodetected. If nil is returned, the media type will be inferred some
  # other way, such as by identifier extension or magic bytes.
  #
  # @param options [Hash] Empty hash.
  # @return [String, nil]
  #
  def jdbcsource_media_type(options = {}); end

  ##
  # @param options [Hash] Empty hash.
  # @return [String] SQL statement that selects the BLOB corresponding to the
  #                  value returned by `jdbcsource_database_identifier()`.
  #
  def jdbcsource_lookup_sql(options = {}); end

  ##
  # N.B.: this method should not try to perform authorization. `authorize()`
  # should be used instead.
  #
  # @param options [Hash] Empty hash.
  # @return [Hash<String,Object>,nil] Hash containing `bucket` and `key` keys;
  #                                   or nil if not found.
  #
  def s3source_object_info(options = {}); end

  ##
  # Tells the server what overlay, if any, to apply to an image in response
  # to a request. Will be called upon all image requests to any endpoint if
  # overlays are enabled and the overlay strategy is set to `ScriptStrategy`
  # in the application configuration.
  #
  # N.B.: When a string overlay is too large or long to fit entirely within
  # the image, it won't be drawn. Consider breaking long strings with LFs (\n).
  #
  # @param options [Hash] Empty hash.
  # @return [Hash<String,String>,nil] For image overlays, a hash with `image`,
  #         `position`, and `inset` keys. For string overlays, a hash with
  #         `background_color`, `color`, `font`, `font_min_size`, `font_size`,
  #         `font_weight`, `glyph_spacing`,`inset`, `position`, `string`,
  #         `stroke_color`, and `stroke_width` keys.
  #         Return nil for no overlay.
  #
  def overlay(options = {}); end

  ##
  # Tells the server what regions of an image to redact in response to a
  # particular request. Will be called upon all image requests to any endpoint
  # if redactions are enabled in the application configuration.
  #
  # @param options [Hash] Empty hash.
  # @return [Array<Hash<String,Integer>>] Array of hashes, each with `x`, `y`,
  #         `width`, and `height` keys; or an empty array if no redactions are
  #         to be applied.
  #
  def redactions(_options = {})
    []
  end

  ##
  # Returns XMP metadata to embed in the derivative image.
  #
  # Source image metadata is available in the `metadata` context key, and has
  # the following structure:
  #
  # {
  #     "exif": {
  #         "tagSet": "Baseline TIFF",
  #         "fields": {
  #             "Field1Name": value,
  #             "Field2Name": value,
  #             "EXIFIFD": {
  #                 "tagSet": "EXIF",
  #                 "fields": {
  #                     "Field1Name": value,
  #                     "Field2Name": value
  #                 }
  #             }
  #         }
  #     },
  #     "iptc": [
  #         "Field1Name": value,
  #         "Field2Name": value
  #     ],
  #     "xmp_string": "<rdf:RDF>...</rdf:RDF>",
  #     "xmp_model": https://jena.apache.org/documentation/javadoc/jena/org/apache/jena/rdf/model/Model.html
  #     "native": {
  #         # structure varies
  #     }
  # }
  #
  # * The `exif` key refers to embedded EXIF data. This also includes IFD0
  #   metadata from source TIFFs, whether or not an EXIF IFD is present.
  # * The `iptc` key refers to embedded IPTC IIM data.
  # * The `xmp_string` key refers to raw embedded XMP data, which may or may
  #   not contain EXIF and/or IPTC information.
  # * The `xmp_model` key contains a Jena Model object pre-loaded with the
  #   contents of `xmp_string`.
  # * The `native` key refers to format-specific metadata.
  #
  # Any combination of the above keys may be present or missing depending on
  # what is available in a particular source image.
  #
  # Only XMP can be embedded in derivative images. See the user manual for
  # examples of working with the XMP model programmatically.
  #
  # @return [String,Model,nil] String or Jena model containing XMP data to
  #                            embed in the derivative image, or nil to not
  #                            embed anything.
  #
  def metadata(_options = {})
    nil
  end
end
