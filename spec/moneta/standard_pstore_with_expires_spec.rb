describe 'standard_pstore_with_expires', isolate: true, unsupported: defined?(JRUBY_VERSION) do
  let(:t_res){ 0.1 }
  let(:min_ttl){ t_res }

  moneta_store :PStore do
    {file: File.join(tempdir, "simple_pstore_with_expires"), expires: true}
  end

  moneta_loader{ |value| value }

  moneta_specs STANDARD_SPECS.with_expires
end
