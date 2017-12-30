describe 'standard_lmdb' do
  moneta_store :LMDB do
    {dir: File.join(tempdir, "simple_lmdb")}
  end

  moneta_specs STANDARD_SPECS.without_concurrent
end
