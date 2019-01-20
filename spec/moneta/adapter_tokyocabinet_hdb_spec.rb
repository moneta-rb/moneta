describe 'adapter_tokyocabinet_hdb', unstable: RUBY_ENGINE == 'jruby' do
  moneta_build do
    Moneta::Adapters::TokyoCabinet.new(file: File.join(tempdir, "adapter_tokyocabinet_hdb"), type: :hdb)
  end

  moneta_specs ADAPTER_SPECS.without_multiprocess.with_each_key
end
