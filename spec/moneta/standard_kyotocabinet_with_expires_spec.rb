describe 'standard_kyotocabinet_with_expires' do
  moneta_store :KyotoCabinet do
    {file: File.join(tempdir, "simple_kyotocabinet_with_expires.kch"), expires: true}
  end

  moneta_specs STANDARD_SPECS.without_multiprocess.with_expires
end
