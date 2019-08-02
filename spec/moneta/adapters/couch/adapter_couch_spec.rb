require_relative '../faraday_helper.rb'

describe 'adapter_couch', adapter: :Couch do
  include_context :faraday_adapter

  moneta_build do
    Moneta::Adapters::Couch.new(db: 'adapter_couch', adapter: faraday_adapter)
  end

  moneta_specs ADAPTER_SPECS.without_increment.simplevalues_only.without_path.with_each_key

  describe '#clear' do
    shared_examples :no_compact do
      it 'does not post to the _compact endpoint' do
        expect(store).not_to receive(:post).with('_compact', any_args)
        store.clear(options)
      end
    end

    context 'without a :compact option' do
      let(:options) { {} }
      include_examples :no_compact
    end

    context 'with compact: true' do
      it 'posts to the _compact endpoint' do
        expect(store).to receive(:post).with('_compact', any_args)
        store.clear(compact: true)
      end
    end

    context 'with compact: false' do
      let(:options) { { compact: false } }
      include_examples :no_compact
    end

    context 'with await_compact: true' do
      it "waits for compaction to complete" do
        # This simulates an empty DB, so no deletes
        expect(store).to receive(:get).with('_all_docs', any_args).ordered { { 'rows' => [] } }

        # Next, compact is called.
        expect(store).to receive(:post).with('_compact', any_args).ordered

        # We expect the method to call get the DB info as many times as the true value is returned.
        expect(store).to receive(:get).twice.with('', any_args).ordered { { 'compact_running' => true } }
        expect(store).to receive(:get).once.with('', any_args).ordered { { 'compact_running' => false } }
        store.clear(compact: true, await_compact: true)
      end
    end

    context 'with await_compact: false' do
      it "does not wait for compaction to complete" do
        expect(store).to receive(:get).with('_all_docs', any_args).ordered { { 'rows' => [] } }
        expect(store).to receive(:post).with('_compact', any_args).ordered
        expect(store).not_to receive(:get).with('', any_args).ordered
        store.clear(compact: true, await_compact: false)
      end
    end
  end
end
