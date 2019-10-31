# frozen_string_literal: true

require 'java'
require 'delegates'
require 'openssl'
require 'cgi'

describe CustomDelegate do
  # Testing setup...

  iv = 'abcdefghijklmnop'
  cipher = OpenSSL::Cipher::AES256.new :CBC
  cipher.encrypt
  cipher.key = ENV['CIPHER_KEY']
  cipher.iv = iv
  cipher_text = cipher.update(ENV['CIPHER_TEXT'] + ' random stuff') + cipher.final
  auth_cookie_value = cipher_text.unpack('H*')[0].upcase

  # Now the testing begins...

  it 'passes if the requested item is an info.json file' do
    delegate = described_class.new
    delegate.context = {
      'request_uri' => 'http://example.org/iiif/asdfasdf/info.json',
      'full_size' => { 'width' => '1024', 'height' => '1024' }
    }
    expect(delegate.authorize).to eq(true)
  end

  it 'fails to authenticate if only an irrelevant cookie is passed' do
    delegate = described_class.new
    delegate.context = {
      'request_uri' => 'http://example.org/iiif/asdfasdf/full/pct:70/0/default.jpg',
      'full_size' => { 'width' => '1024', 'height' => '1024' },
      :cookies => { 'nope' => 0 }
    }
    expect(delegate.authorize).to eq(false)
  end

  it 'fails if only one of our necessary cookies is passed' do
    delegate = described_class.new
    delegate.context = {
      'request_uri' => 'http://example.org/iiif/asdfasdf/full/pct:70/0/default.jpg',
      'full_size' => { 'width' => '1024', 'height' => '1024' },
      :cookies => {
        'sinai_authenticated' => auth_cookie_value
      }
    }
    expect(delegate.authorize).to eq(false)
  end

  it 'passes if we send the necessary cookies with acceptible values' do
    delegate = described_class.new
    delegate.context = {
      'request_uri' => 'http://example.org/iiif/asdfasdf/full/pct:70/0/default.jpg',
      'full_size' => { 'width' => '1024', 'height' => '1024' },
      :cookies => {
        'initialization_vector' => iv,
        'sinai_authenticated' => auth_cookie_value
      }
    }
    expect(delegate.authorize).to be(true)
  end

  it 'passes if delegate source is set to S3Source' do
    delegate = described_class.new
    delegate.context = {
      'request_uri' => 'http://example.org/iiif/asdfasdf/full/pct:70/0/default.jpg',
      'full_size' => { 'width' => '1024', 'height' => '1024' },
      :cookies => {
        'initialization_vector' => iv,
        'sinai_authenticated' => auth_cookie_value
      }
    }
    expect(delegate.source).to be('S3Source')
  end
end
