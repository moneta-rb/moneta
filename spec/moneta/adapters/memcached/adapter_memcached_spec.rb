require_relative './helper.rb'

describe 'adapter_memcached', adapter: :Memcached do
  include_context :start_memcached, 11216

  moneta_build do
    Moneta::Adapters::Memcached.new(server: "127.0.0.1:11216")
  end

  it "is a Memcached adapter" do
    expect(store).to be_a_memcached_adapter
  end
end
