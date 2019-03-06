describe 'standard_leveldb_with_expires', unsupported: defined?(JRUBY_VERSION), adapter: :LevelDB do
  let(:t_res) { 0.125 }
  let(:min_ttl) { t_res }
  use_timecop

  moneta_store :LevelDB do
    {dir: File.join(tempdir, "standard_leveldb_with_expires"), expires: true}
  end

  moneta_specs STANDARD_SPECS.without_multiprocess.with_expires
end
