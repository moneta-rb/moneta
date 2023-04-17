describe 'standard_kyotocabinet_with_expires', unsupported: defined?(JRUBY_VERSION)|| ::Gem::Version.new(RUBY_ENGINE_VERSION) >= ::Gem::Version.new('2.7.0'), adapter: :KyotoCabinet do
  let(:t_res) { 0.125 }
  let(:min_ttl) { t_res }
  use_timecop

  moneta_store :KyotoCabinet do
    {
      file: File.join(tempdir, "simple_kyotocabinet_with_expires.kch"),
      expires: true
    }
  end

  moneta_specs STANDARD_SPECS.without_multiprocess.with_expires
end
