describe 'standard_tokyocabinet', unsupported: defined?(JRUBY_VERSION), adapter: :TokyoCabinet do
  moneta_store :TokyoCabinet do
    {file: File.join(tempdir, "simple_tokyocabinet")}
  end

  moneta_specs STANDARD_SPECS.without_multiprocess
end
