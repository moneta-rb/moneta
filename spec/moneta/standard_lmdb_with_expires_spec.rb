describe 'standard_lmdb_with_expires' do
  moneta_store :LMDB do
    {dir: File.join(tempdir, "simple_lmdb_with_expires"), expires: true}
  end

  moneta_specs STANDARD_SPECS.without_concurrent.with_expires
end
