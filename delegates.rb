require 'net/http'
require 'uri'
require 'json'
require 'java'

##
# Delegate script to connect Cantaloupe to Fedora. It slices a piece of
# Cantaloupe for Samvera to use.
#
class CustomDelegate

  logger = Java::edu.illinois.library.cantaloupe.script.Logger

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
  # Tells the server whether the given request is authorized. Will be called
  # upon all image requests to any endpoint.
  #
  # Implementations should assume that the underlying resource is available,
  # and not try to check for it.
  #
  # @param options [Hash] Empty hash.
  # @return [Boolean] Whether the request is authorized.
  #
  def authorize?(options = {})
    true
  end

  ##
  # Tells the server which source to use for the given identifier.
  #
  # @param options [Hash] Empty hash.
  # @return [String] Source name.
  #
  def source(options = {})
    'HttpSource'
  end

  ##
  # @param options [Hash] Empty hash.
  # @return [String,Hash<String,String>,nil] String URI; Hash with `uri` key,
  #         and optionally `username` and `secret` keys; or nil if not found.
  #
  def httpsource_resource_info(options = {})
    item_id = context['identifier']
    image_id = get_image_id(item_id)

    return { 'uri' => get_file_url(image_id) }
  end

  def get_file_url(image_id)
    # Split the parts into Fedora's pseudo-pairtree (only first four pairs)
    paths = image_id.split(/(.{0,2})/).reject { |c| c.empty? }[0, 4]
    
    uri = URI(ENV['FEDORA_URL'] + ENV['FEDORA_BASE_PATH'] + '/' + paths.join('/') + '/' + image_id)
    http = Net::HTTP.new(uri.host, uri.port)

    request = Net::HTTP::Get.new(uri.request_uri)
    request['User-Agent'] = 'Californica cantaloupe delegate'
    request['Accept'] = 'application/ld+json'
    response = http.request(request)

    if response.code == "200"
      result = JSON.parse(response.body)
      file_id = result.first['http://pcdm.org/models#hasFile']
      logger.debug("File URL: " + file_id.first['@id'] + " (from Fedora)")
      return file_id.first['@id']
    else
      return ''
    end
  end

  ##
  # Gets the image ID for the item in hand. The SOLR_URL, passed in
  # through the environment, should be in the form
  # 'http://localhost:8983/solr/californica' (i.e., including the core name)
  #
  # @param item_id [String] The item ID
  #
  def get_image_id(item_id)
    uri = URI(ENV['SOLR_URL'] + '/select?q=id:' + item_id)
    http = Net::HTTP.new(uri.host, uri.port)
    
    request = Net::HTTP::Get.new(uri.request_uri)
    request['User-Agent'] = 'Cantaloupe delegate'
    request['Accept'] = 'application/ld+json'
    response = http.request(request)
    contentType = response['content-type']

    if response.code == "200"
      result = JSON.parse(response.body)
      item_id = result['response']['docs'][0]['hasRelatedImage_ssim'][0]
      logger.debug('Image ID: ' + item_id + ' (from Solr)')
      return item_id
    else
      return ''
    end
  end
end
