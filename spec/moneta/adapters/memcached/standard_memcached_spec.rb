require_relative '../memcached_helper.rb'

describe 'standard_memcached', adapter: :Memcached do
  include_context :start_memcached, 11220

  moneta_store :Memcached, server: "127.0.0.1:11220"

  it "uses one of the Memcached adapters" do
    # recurse down through adapters
    adapter = store.adapter
    while adapter.respond_to?(:adapter)
      adapter = adapter.adapter
    end

    expect(adapter).to be_a_memcached_adapter
  end
end
