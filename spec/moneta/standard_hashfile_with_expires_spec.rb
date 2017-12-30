describe 'standard_hashfile_with_expires' do
  moneta_store :HashFile do
    {dir: File.join(tempdir, "simple_hashfile_with_expires"),
     expires: true}
  end

  moneta_specs STANDARD_SPECS.with_expires
end
