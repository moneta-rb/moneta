describe 'standard_pstore_with_expires', unsupported: defined?(JRUBY_VERSION) do
  let(:t_res) { 0.125 }
  let(:min_ttl) { t_res }
  use_timecop

  moneta_store :PStore do
    {file: File.join(tempdir, "simple_pstore_with_expires"), expires: true}
  end

  moneta_loader{ |value| value }

  moneta_specs STANDARD_SPECS.with_expires
end
