describe 'adapter_tokyocabinet_bdb', unsupported: defined?(JRUBY_VERSION), adapter: :TokyoCabinet do
  moneta_build do
    Moneta::Adapters::TokyoCabinet.new(file: File.join(tempdir, "adapter_tokyocabinet_bdb"), type: :bdb)
  end

  moneta_specs ADAPTER_SPECS.without_multiprocess.with_each_key
end
