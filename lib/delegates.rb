require 'net/http'
require 'uri'
require 'json'
require 'java'

##
# Delegate script to connect Cantaloupe to Fedora. It slices a piece of
# Cantaloupe for Samvera to consume.
#
# This is a first pass and doesn't have a lot of error checking built in yet.
# It also assumes a very basic use case of a single image on an item.
#
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
  # * `client_ip`       [String] Client IP address.
  # * `cookies`         [Hash<String,String>] Hash of cookie name-value pairs.
  # * `identifier`      [String] Image identifier.
  # * `request_headers` [Hash<String,String>] Hash of header name-value pairs.
  # * `request_uri`     [String] Public request URI.
  #
  # It will contain the following additional string keys in response to image
  # requests:
  #
  # * `full_size`      [Hash<String,Integer>] Hash with `width` and `height`
  #                    keys corresponding to the pixel dimensions of the
  #                    source image.
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
  def authorize(options = {})
    authorized?(options)
  end

  ##
  # Tells the server whether to redirect in response to the request. Will be
  # called upon all image requests.
  #
  # @param options [Hash] Empty hash.
  # @return [Hash<String,Object>,nil] Hash with `location` and `status_code`
  #         keys. `location` must be a URI string; `status_code` must be an
  #         integer from 300 to 399. Return nil for no redirect.
  #
  def redirect(_options = {})
    nil
  end

  ##
  # Tells the server whether the given request is authorized. Will be called
  # upon all image requests to any endpoint.
  #
  # Implementations should assume that the underlying resource is available,
  # and not try to check for it.
  #
  # @param options [Hash] Empty hash.
  # @return [Boolean] Whether the request is authorized.
  #
  def authorized?(_options = {})
    @request = context['request_uri'].split('/')
    @width = context['full_size']['width'] unless context['full_size'].nil?

    check_region
    check_requested_width

    !(full? || oversized?)
  end

  ##
  # Used to add additional keys to an information JSON response. See the
  # [Image API specification](http://iiif.io/api/image/2.1/#image-information).
  #
  # @param options [Hash] Empty hash.
  # @return [Hash] Hash that will be merged into an IIIF Image API 2.x
  #                information response. Return an empty hash to add nothing.
  #
  def extra_iiif2_information_response_keys(_options = {})
    {}
  end

  ##
  # Tells the server which source to use for the given identifier.
  #
  # @param options [Hash] Empty hash.
  # @return [String] Source name.
  #
  def source(_options = {})
    identifier = context['identifier']
    if identifier.start_with?('Masters/')
      'FilesystemSource'
    else
      'HttpSource'
    end
  end

  ##
  # Gets the HTTP-sourced image resource information.
  #
  # @param options [Hash] Empty hash.
  # @return [String,Hash<String,String>,nil] String URI; Hash with `uri` key,
  #         and optionally `username` and `secret` keys; or nil if not found.
  #
  def httpsource_resource_info(_options = {})
    file_id = context['identifier']

    # Split the parts into Fedora's pseudo-pairtree (only first four pairs)
    paths = file_id.split(/(.{0,2})/).reject!(&:empty?)[0, 4]

    fedora_base_url = ENV['FEDORA_URL'] + ENV['FEDORA_BASE_PATH']

    fedora_base_url + '/' + paths.join('/') + '/' + file_id
  end

  private

  def check_region
    @region = @request[@request.length - 4]
  end

  def check_requested_width
    @requested_width = @request[@request.length - 3].split(',')[0]
  end

  # Limit full size requests
  def full?
    @region == 'full' && %w[full max].include?(@requested_width)
  end

  # Don't allow image requests that are more than 50% of the original
  def oversized?
    over_max_pct? || @requested_width.to_i > (@width.to_f * 0.5).to_i
  end

  # Limit high pct requests for full images (of any region)
  def over_max_pct?
    @requested_width.split(':')[1].to_i > 79 if @requested_width.include? 'pct:'
  end
end
