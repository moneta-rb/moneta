require_relative '../faraday_helper.rb'

describe 'adapter_couch', adapter: :Couch do
  include_context :faraday_adapter

  moneta_build do
    Moneta::Adapters::Couch.new(db: 'adapter_couch', adapter: faraday_adapter)
  end

  moneta_specs ADAPTER_SPECS.without_increment.simplevalues_only.without_path.with_each_key

  shared_examples :batch do
    shared_examples :no_batch do
      it "does not add 'batch=ok' to the query'" do
        expect(store).not_to receive(:request).with(any_args, hash_including(query: hash_including(batch: 'ok')))
        expect(store).to receive(:request)
        store.public_send(m, *args, options)
      end
    end

    context 'without a :batch option' do
      let(:options) { {} }
      include_examples(:no_batch)
    end

    context 'with batch: false' do
      let(:options) { { batch: false } }
      include_examples(:no_batch)
    end

    context 'with batch: true' do
      let(:options) { { batch: true } }

      it "adds 'batch=ok' to the query'" do
        expect(store).to receive(:request).with(instance_of(Symbol), instance_of(String), any_args,
                                                hash_including(expect: 202, query: hash_including(batch: 'ok')))
        store.public_send(m, *args, options)
      end
    end
  end

  shared_examples :full_commit do
    context 'without a :full_commit option' do
      let(:options) { {} }

      it "does not add a 'X-Couch-Full-Commit' header'" do
        expect(store).not_to receive(:request)
          .with(any_args, hash_including(headers: hash_including('X-Couch-Full-Commit' => instance_of(String))))
        expect(store).to receive(:request).ordered
        store.public_send(m, *args, options)
      end
    end

    context 'with full_commit: true' do
      let(:options) { { full_commit: true } }

      it "adds 'X-Couch-Full-Commit: true' to the headers'" do
        expect(store).to receive(:request)
          .with(instance_of(Symbol), instance_of(String), any_args,
                hash_including(headers: hash_including('X-Couch-Full-Commit' => 'true')))
          .ordered
        store.public_send(m, *args, options)
      end
    end

    context 'with full_commit: false' do
      let(:options) { { full_commit: false } }

      it "adds 'X-Couch-Full-Commit: false' to the headers'" do
        expect(store).to receive(:request)
          .with(instance_of(Symbol), instance_of(String), any_args,
                hash_including(headers: hash_including('X-Couch-Full-Commit' => 'false')))
          .ordered
        store.public_send(m, *args, options)
      end
    end
  end

  describe '#store' do
    let(:m) { :store }
    let(:args) { ['a', 'b'] }

    include_examples :batch
    include_examples :full_commit
  end

  describe '#delete' do
    let(:m) { :delete }
    let(:args) { ['a'] }

    before do
      expect(store).to receive(:request).with(:get, 'a', any_args).ordered do
        Faraday::Response.new(
          Faraday::Env.from(status: 200,
                            body: '{"type":"Hash","test":1}',
                            response_headers: { 'ETag' => '"testrev"' }))
      end
    end

    include_examples :batch
    include_examples :full_commit
  end

  describe '#merge!' do
    let(:m) { :merge! }
    let(:args) { [{'a' => '1'}] }

    before do
      expect(store).to receive(:request).with(:get, '_all_docs', any_args).ordered do
        { 'rows' => [] }
      end

      allow(store).to receive(:request).with(:post, '_bulk_docs', any_args) do
        [
          {
            "ok" => true,
            "id" => 'a',
            "rev" => 'testrev'
          }
        ]
      end
    end

    include_examples :full_commit
  end

  describe '#clear' do
    context 'changing full commit behaviour' do
      let(:m) { :clear }
      let(:args) { [] }

      # This will make the clear method proceed to deletion
      before do
        responses = [
          {
            'rows' => [
              {
                'id' => 'test',
                'value' => {
                  'rev' => 'testrev'
                }
              }
            ]
          },
          { 'rows' => [] }
        ]

        expect(store).to receive(:request).at_least(:once).with(:get, '_all_docs', any_args).ordered do
          responses.shift
        end
      end

      include_examples :full_commit
    end

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
