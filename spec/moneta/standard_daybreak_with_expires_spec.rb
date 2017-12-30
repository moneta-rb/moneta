describe 'standard_daybreak_with_expires' do
  moneta_store :Daybreak do
    {file: File.join(tempdir, "simple_daybreak_with_expires"), expires: true}
  end

  moneta_specs STANDARD_SPECS.without_multiprocess.with_expires
end
