describe 'adapter_lmdb', unsupported: defined?(JRUBY_VERSION), adapter: :LMDB do
  moneta_build do
    Moneta::Adapters::LMDB.new(dir: File.join(tempdir, "adapter_lmdb"))
  end

  moneta_specs ADAPTER_SPECS.without_concurrent.with_each_key
end
