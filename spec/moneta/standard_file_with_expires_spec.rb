describe 'standard_file_with_expires', isolate: true do
  let(:t_res){ 0.1 }
  let(:min_ttl){ t_res }

  moneta_store :File do
    {dir: File.join(tempdir, "simple_file_with_expires"), expires: true}
  end

  moneta_specs STANDARD_SPECS.with_expires
end
