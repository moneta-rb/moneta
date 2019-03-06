describe 'standard_lmdb', unsupported: defined?(JRUBY_VERSION), adapter: :LMDB do
  moneta_store :LMDB do
    {dir: File.join(tempdir, "simple_lmdb")}
  end

  moneta_specs STANDARD_SPECS.without_concurrent
end
