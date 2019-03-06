describe 'adapter_kyotocabinet', unsupported: defined?(JRUBY_VERSION), adapter: :KyotoCabinet do
  moneta_build do
    Moneta::Adapters::KyotoCabinet.new(file: File.join(tempdir, "adapter_kyotocabinet.kch"))
  end

  moneta_specs ADAPTER_SPECS.without_multiprocess.with_each_key
end
