describe 'standard_pstore', unsupported: RUBY_ENGINE == 'jruby' do
  moneta_store :PStore do
    {file: File.join(tempdir, "simple_pstore")}
  end

  moneta_loader{ |value| value }

  moneta_specs STANDARD_SPECS
end
