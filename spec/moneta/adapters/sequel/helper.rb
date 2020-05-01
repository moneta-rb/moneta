RSpec.shared_context :sequel do
  def mysql_uri database=nil
    database ||= mysql_database1
    if defined?(JRUBY_VERSION)
      "jdbc:mysql://localhost/#{database}?user=#{mysql_username}&useSSL=false"
    else
      "mysql2://#{mysql_username}:@localhost/#{database}"
    end
  end

  def sqlite_uri file_name
    "#{defined?(JRUBY_VERSION) && 'jdbc:'}sqlite://" + File.join(tempdir, file_name)
  end

  def postgres_options database=nil
    database ||= postgres_database1
    if defined?(JRUBY_VERSION)
      {db: "jdbc:postgresql://localhost/#{database}?user=#{postgres_username}"}
    else
      {
        db: "postgres://localhost/#{database}",
        user: postgres_username
      }
    end
  end

  def postgres_hstore_options database=nil
    postgres_options(database).merge \
      table: 'hstore_table1',
      hstore: 'row'
  end

  def h2_uri
    "jdbc:h2:" + tempdir
  end
end 

RSpec.shared_examples :adapter_sequel do |specs, optimize: true|
  shared_examples :each_key_server do
    context "with each_key server" do
      let(:opts) do
        base_opts.merge(
          servers: {each_key: {}},
          each_key_server: :each_key
        )
      end

      moneta_specs specs
    end

    context "without each_key server" do
      let(:opts) { base_opts }
      moneta_specs specs
    end
  end

  if optimize
    context 'with backend optimizations' do
      let(:base_opts) { {table: "adapter_sequel"} }

      include_examples :each_key_server
    end
  end

  context 'without backend optimizations' do
    let(:base_opts) do
      {
        table: "adapter_sequel",
        optimize: false
      }
    end

    include_examples :each_key_server
  end
end
