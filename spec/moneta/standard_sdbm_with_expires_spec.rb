describe 'standard_sdbm_with_expires', unsupported: defined?(JRUBY_VERSION) do
  let(:t_res) { 0.125 }
  let(:min_ttl) { t_res }
  use_timecop

  moneta_store :SDBM do
    {file: File.join(tempdir, "simple_sdbm_with_expires"), expires: true}
  end

  moneta_specs STANDARD_SPECS.without_multiprocess.with_expires.without_large
end
