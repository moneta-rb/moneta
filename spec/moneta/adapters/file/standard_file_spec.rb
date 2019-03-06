describe 'standard_file', adapter: :File do
  moneta_store :File do
    {dir: File.join(tempdir, "simple_file")}
  end
  
  moneta_specs STANDARD_SPECS
end
