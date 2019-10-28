# frozen_string_literal: true

require 'java'
require 'delegates'
require 'openssl'
require 'cgi'

describe CustomDelegate do
  # Testing setup...

  challenge_url = 'https://sinai-id.org/users/sign_in'
  iv = 'abcdefghijklmnop'
  cipher = OpenSSL::Cipher::AES256.new :CBC
  cipher.encrypt
  cipher.key = ENV['CIPHER_KEY']
  cipher.iv = iv
  cipher_text = cipher.update(ENV['CIPHER_TEXT'] + ' random stuff') + cipher.final
  auth_cookie_value = cipher_text.unpack('H*')[0].upcase

  # Now the tests begin...

  it 'fails to authenticate if cookies are not present' do
    uri = 'http://example.org/iiif/asdfasdf/full/pct:70/0/default.jpg'
    delegate = described_class.new
    delegate.context = {
      'request_uri' => uri,
      'full_size' => { 'width' => '1024', 'height' => '1024' }
    }
    expect(delegate.authorize).to eq([false, { 'challenge' => challenge_url, 'status_code' => 401 }])
  end

  it 'fails to authenticate if only an irrelevant cookie is passed' do
    uri = 'http://example.org/iiif/asdfasdf/full/pct:70/0/default.jpg'
    delegate = described_class.new
    # my_hash = { :nested_hash => { :first_key => 'Hello' } }
    delegate.context = {
      'request_uri' => uri,
      'full_size' => { 'width' => '1024', 'height' => '1024' },
      :cookies => { 'nope' => 0 }
    }
    expect(delegate.authorize).to eq([false, { 'challenge' => challenge_url, 'status_code' => 401 }])
  end

  it 'fails if only one of our necessary cookies is passed' do
    uri = 'http://example.org/iiif/asdfasdf/full/pct:70/0/default.jpg'
    delegate = described_class.new
    delegate.context = {
      'request_uri' => uri,
      'full_size' => { 'width' => '1024', 'height' => '1024' },
      :cookies => {
        'sinai_authenticated' => auth_cookie_value
      }
    }
    expect(delegate.authorize).to eq([false, { 'challenge' => challenge_url, 'status_code' => 401 }])
  end

  it 'passes if we send the necessary cookies with acceptible values' do
    uri = 'http://example.org/iiif/asdfasdf/full/pct:70/0/default.jpg'
    delegate = described_class.new
    delegate.context = {
      'request_uri' => uri,
      'full_size' => { 'width' => '1024', 'height' => '1024' },
      :cookies => {
        'initialization_vector' => iv,
        'sinai_authenticated' => auth_cookie_value
      }
    }
    expect(delegate.authorize).to be(true)
  end
end
