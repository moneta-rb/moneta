describe 'standard_file_with_expires', adapter: :File do
  let(:t_res) { 0.125 }
  let(:min_ttl) { t_res }
  use_timecop

  moneta_store :File do
    {dir: File.join(tempdir, "simple_file_with_expires"), expires: true}
  end

  moneta_specs STANDARD_SPECS.with_expires
end
