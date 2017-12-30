describe 'standard_leveldb_with_expires' do
  moneta_store :LevelDB do
    {dir: File.join(tempdir, "standard_leveldb_with_expires"), expires: true}
  end

  moneta_specs STANDARD_SPECS.without_multiprocess.with_expires
end
