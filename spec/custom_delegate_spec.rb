require 'java'
require 'delegates'
require 'openssl'
require 'cgi'

describe CustomDelegate do

  # we need some fake secrets to test our cookie handling, let's make some
  todays_date = "today"
  cipher = OpenSSL::Cipher::AES256.new :CBC
  cipher.encrypt
  myIV = cipher.random_iv
  myEscapedIV = CGI.escapeHTML(myIV)
  # cipher.key = OpenSSL::Random.random_bytes(32)
  cipher.key = ENV['CIPHER_KEY']
  myCipherText = cipher.update("Authenticated #{todays_date}") + cipher.final
  myEscapedCipherText = CGI.escapeHTML(myCipherText)

  it 'fails to authenticate if cookies are not present' do
    uri = 'http://example.org/iiif/asdfasdf/full/pct:70/0/default.jpg'
    delegate = described_class.new
    delegate.context = { 'request_uri' => uri, 'full_size' => { 'width' => '1024', 'height' => '1024' } }
    expect(delegate.authorize).to eq([false, {"challenge"=>"https://sinai-id.org/users/sign_in", "status_code"=>401}])
  end

  it 'fails to authenticate if only an irrelevant cookie is passed' do
    uri = 'http://example.org/iiif/asdfasdf/full/pct:70/0/default.jpg'
    delegate = described_class.new
    #my_hash = { :nested_hash => { :first_key => 'Hello' } }
    delegate.context = { 'request_uri' => uri, 'full_size' => { 'width' => '1024', 'height' => '1024' }, :cookies => {'nope' => 0 } }
    expect(delegate.authorize).to eq([false, {"challenge"=>"https://sinai-id.org/users/sign_in", "status_code"=>401}])
  end

  it 'fails if only one of our necessary cookies is passed' do
    uri = 'http://example.org/iiif/asdfasdf/full/pct:70/0/default.jpg'
    delegate = described_class.new
    delegate.context = { 'request_uri' => uri, 'full_size' => { 'width' => '1024', 'height' => '1024' }, :cookies => { 'sinai_authenticated' => myEscapedCipherText } }
    expect(delegate.authorize).to eq([false, {"challenge"=>"https://sinai-id.org/users/sign_in", "status_code"=>401}])
  end

  it 'passes if we send the necessary cookies with acceptible values' do
    uri = 'http://example.org/iiif/asdfasdf/full/pct:70/0/default.jpg'
    delegate = described_class.new
    delegate.context = { 'request_uri' => uri, 'full_size' => { 'width' => '1024', 'height' => '1024' }, :cookies => {'initialization_vector' => myEscapedIV, 'sinai_authenticated' => myEscapedCipherText } }
    expect(delegate.authorize).to be(true)
  end

end
