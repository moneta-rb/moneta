describe 'standard_file_with_expires' do
  moneta_store :File do
    {dir: File.join(tempdir, "simple_file_with_expires"), expires: true}
  end
  
  moneta_specs STANDARD_SPECS.with_expires
end
