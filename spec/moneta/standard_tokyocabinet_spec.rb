describe 'standard_tokyocabinet', unsupported: RUBY_ENGINE == 'jruby' do
  moneta_store :TokyoCabinet do
    {file: File.join(tempdir, "simple_tokyocabinet")}
  end

  moneta_specs STANDARD_SPECS.without_multiprocess
end
