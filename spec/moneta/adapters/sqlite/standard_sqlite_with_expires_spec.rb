describe 'standard_sqlite_with_expires', unsupported: defined?(JRUBY_VERSION), adapter: :Sqlite do
  let(:t_res) { 0.125 }
  let(:min_ttl) { 1 }
  use_timecop

  moneta_store :Sqlite do
    {
      file: File.join(tempdir, "standard_sqlite_with_expires"),
      expires: true,
      journal_mode: :wal
    }
  end

  moneta_specs STANDARD_SPECS.with_expires.without_concurrent
end
