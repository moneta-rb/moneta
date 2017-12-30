describe 'standard_gdbm' do
  moneta_store :GDBM do
    {file: File.join(tempdir, "simple_gdbm")}
  end

  moneta_specs STANDARD_SPECS.without_multiprocess
end
