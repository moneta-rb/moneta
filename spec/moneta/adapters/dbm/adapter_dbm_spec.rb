describe 'adapter_dbm', unsupported: defined?(JRUBY_VERSION), adapter: :DBM do
  moneta_build do
    Moneta::Adapters::DBM.new(file: File.join(tempdir, "adapter_dbm"))
  end

  moneta_specs ADAPTER_SPECS.with_each_key.without_multiprocess
end
