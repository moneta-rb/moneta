describe 'standard_pstore_with_expires' do
  moneta_store :PStore do
    {file: File.join(tempdir, "simple_pstore_with_expires"), expires: true}
  end

  moneta_loader{ |value| value }

  moneta_specs STANDARD_SPECS.with_expires
end
