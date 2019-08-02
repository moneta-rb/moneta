RSpec.shared_context :start_memcached do |port|
  before :context do
    @memcached = spawn("memcached -p #{port}")
    sleep 0.5
  end

  after :context do
    Process.kill("TERM", @memcached)
    Process.wait(@memcached)
    @memcached = nil
  end

  let :be_a_memcached_adapter do
    klasses = [
      defined?(::Moneta::Adapters::MemcachedDalli) ? ::Moneta::Adapters::MemcachedDalli : nil,
      defined?(::Moneta::Adapters::MemcachedNative) ? ::Moneta::Adapters::MemcachedNative : nil
    ].compact
    klasses.map { |klass| be_instance_of(klass) }.inject(:or)
  end
end
