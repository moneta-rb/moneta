describe 'standard_kyotocabinet', unsupported: defined?(JRUBY_VERSION) || ::Gem::Version.new(RUBY_ENGINE_VERSION) >= ::Gem::Version.new('2.7.0'), adapter: :KyotoCabinet do
  moneta_store :KyotoCabinet do
    {file: File.join(tempdir, "simple_kyotocabinet.kch")}
  end

  moneta_specs STANDARD_SPECS.without_multiprocess
end
