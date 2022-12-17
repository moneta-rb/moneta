describe 'standard_gdbm_with_expires', adapter: :GDBM do
  let(:t_res) { 0.125 }
  let(:min_ttl) { t_res }
  use_timecop

  moneta_store :GDBM do |metadata: nil, **options|
    p metadata
    {file: File.join(tempdir, "simple_gdbm_with_expires"), expires: true, metadata: metadata}
  end

  moneta_specs STANDARD_SPECS.without_multiprocess.with_expires.with_each_key.with_metadata
end
