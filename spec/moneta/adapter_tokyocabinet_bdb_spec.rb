describe 'adapter_tokyocabinet_bdb' do
  moneta_build do
    Moneta::Adapters::TokyoCabinet.new(file: File.join(tempdir, "adapter_tokyocabinet_bdb"), type: :bdb)
  end

  moneta_specs ADAPTER_SPECS.without_multiprocess
end
