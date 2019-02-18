describe 'standard_lmdb_with_expires', unsupported: defined?(JRUBY_VERSION) do
  let(:t_res) { 1 }
  let(:min_ttl) { t_res }
  use_timecop

  moneta_store :LMDB do
    {dir: File.join(tempdir, "simple_lmdb_with_expires"), expires: true}
  end

  moneta_specs STANDARD_SPECS.without_concurrent.with_expires
end
