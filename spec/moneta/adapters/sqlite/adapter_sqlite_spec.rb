describe 'adapter_sqlite', unsupported: defined?(JRUBY_VERSION), adapter: :Sqlite do
  moneta_build do
    Moneta::Adapters::Sqlite.new(file: File.join(tempdir, "adapter_sqlite"))
  end

  moneta_specs ADAPTER_SPECS.with_values(:nil).without_concurrent.with_each_key
end
