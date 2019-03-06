require 'java'
require 'delegates'

describe CustomDelegate do
  it 'returns image URL from Fedora' do
    id = '4x51hj00j/files/8891b5b6-8ae4-462d-95fc-f930d519d21b'
    delegate = described_class.new
    delegate.context = { 'identifier' => id, 'client_ip' => '127.0.0.1' }
    image_url = 'http://localhost:8984/fcrepo/rest/prod/4x/51/hj/00/' + id
    expect(delegate.httpsource_resource_info).to eq(image_url)
  end

  it 'authenticates iiif full request' do
    uri = 'http://example.org/iiif/asdfasdf/full/full/0/default.jpg'
    delegate = described_class.new
    delegate.context = { 'request_uri' => uri, 'client_ip' => '127.0.0.1' }
    expect(delegate.authorized?).to be(false)
  end

  it 'authenticates iiif simple request' do
    uri = 'http://example.org/iiif/asdfasdf/125,15,120,140/full/0/default.jpg'
    delegate = described_class.new
    delegate.context = { 'request_uri' => uri, 'full_size' => { 'width' => '1024', 'height' => '1024' } }
    expect(delegate.authorized?).to be(true)
  end
end
