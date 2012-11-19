require 'helper'

begin
  describe Juno::DataMapper do
    before do
      DataMapper.setup(:default, :adapter => :in_memory)
    end

    describe 'with the default repository' do
      def new_store
        Juno::DataMapper.new(:setup => "sqlite3://#{make_tempdir}/datamapper.sqlite3")
      end

      after do
        Juno::DataMapper::Store.auto_migrate!(:juno)
      end

      class_eval(&Juno::Specification)
    end

    describe 'when :repository specified' do
      def new_store
        Juno::DataMapper.new(:repository => :sample, :setup => "sqlite3://#{make_tempdir}/datamapper.sqlite3")
      end

      after do
        Juno::DataMapper::Store.auto_migrate!(:sample)
      end

      class_eval(&Juno::Specification)
    end

    describe 'with multiple stores' do
      include Helper

      before do
        @first_store = Juno::DataMapper.new(:setup => "sqlite3://#{make_tempdir}/first.sqlite3")
        @first_store.clear

        @second_store = Juno::DataMapper.new(:repository => :sample, :setup => "sqlite3://#{make_tempdir}/second.sqlite3")
        @second_store.clear
      end

      it 'does not cross contaminate when storing' do
        @first_store['key'] = 'value'
        @second_store['key'] = 'value2'

        @first_store['key'].must_equal 'value'
        @second_store['key'].must_equal 'value2'
      end

      it 'does not cross contaminate when deleting' do
        @first_store['key'] = 'value'
        @second_store['key'] = 'value2'

        @first_store.delete('key').must_equal 'value'
        @first_store.key?('key').must_equal false
        @second_store['key'].must_equal 'value2'
      end
    end
  end
rescue LoadError => ex
  puts "Juno::Datamapper not tested: #{ex.message}"
end
