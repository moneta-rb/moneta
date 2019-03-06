describe 'adapter_pstore', unsupported: defined?(JRUBY_VERSION), adapter: :PStore do
  moneta_build do
    Moneta::Adapters::PStore.new(file: File.join(tempdir, "adapter_pstore"))
  end

  moneta_specs STANDARD_SPECS.with_each_key.without_transform
end
