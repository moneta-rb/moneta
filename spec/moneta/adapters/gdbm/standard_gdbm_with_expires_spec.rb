describe 'standard_gdbm_with_expires', adapter: :GDBM do
  let(:t_res) { 0.125 }
  let(:min_ttl) { t_res }
  use_timecop

  moneta_store :GDBM do
    {file: File.join(tempdir, "simple_gdbm_with_expires"), expires: true}
  end

  moneta_specs STANDARD_SPECS.without_multiprocess.with_expires
end
