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
end
