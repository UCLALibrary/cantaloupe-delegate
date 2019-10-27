require 'java'
require 'delegates'
require 'openssl'
require 'cgi'
require 'active_support'
require 'base64'

describe CustomDelegate do
  challenge_url          = 'https://sinai-id.org/users/sign_in'
  my_escaped_cipher_text = ENV['SINAI_TEST_SESSION_COOKIE']
  my_cookie_name         = ENV['SINAI_COOKIE_NAME']

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

  it 'fails if we send the necessary cookie with a wrong value' do
    uri = 'http://example.org/iiif/asdfasdf/full/pct:70/0/default.jpg'
    delegate = described_class.new
    delegate.context = {
      'request_uri' => uri,
      'full_size' => { 'width' => '1024', 'height' => '1024' },
      :cookies => {
        my_cookie_name => Base64.encode64('wrong')
      }
    }
    expect(delegate.authorize).to eq([false, { 'status_code' => 400 }])
  end

  it 'passes if we send the necessary cookie with an acceptible value' do
    uri = 'http://example.org/iiif/asdfasdf/full/pct:70/0/default.jpg'
    delegate = described_class.new
    delegate.context = {
      'request_uri' => uri,
      'full_size' => { 'width' => '1024', 'height' => '1024' },
      :cookies => {
        my_cookie_name => my_escaped_cipher_text
      }
    }
    expect(delegate.authorize).to be(true)
  end
end
