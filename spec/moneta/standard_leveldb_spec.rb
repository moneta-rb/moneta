describe 'standard_leveldb' do
  moneta_store :LevelDB do
    {dir: File.join(tempdir, "standard_leveldb")}
  end

  moneta_specs STANDARD_SPECS.without_multiprocess
end
