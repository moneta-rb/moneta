describe 'standard_daybreak', adapter: :Daybreak do
  moneta_store :Daybreak do
    {file: File.join(tempdir, "simple_daybreak")}
  end

  moneta_specs STANDARD_SPECS.without_multiprocess
end
