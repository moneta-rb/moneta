describe 'adapter_sequel' do
  moneta_build do
    Moneta::Adapters::Sequel.new(db: (defined?(JRUBY_VERSION) ? "jdbc:mysql://localhost/moneta?user=root" : "mysql2://root:@localhost/moneta"), table: "adapter_sequel")
  end

  moneta_specs ADAPTER_SPECS
end
