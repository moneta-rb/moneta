shared_examples :expires do
  before do
    raise "t_res must be <= min_ttl" unless t_res <= min_ttl
  end

  at_each_usec do
    # All methods that are used for updating that include an :expires parameter
    shared_examples :updater_expiry do
      context "with a positive numeric :expires parameter" do
        before do
          updater.call(expires: min_ttl)
        end

        it 'causes the value to expire after the given number of seconds' do
          keys.zip(values).each do |key, value|
            expect(store.load(key)).to eq value
            expect(store[key]).to eq value
          end
          advance min_ttl + t_res
          keys.each do |key, value|
            expect(store.load(key)).to be_nil
            expect(store[key]).to be_nil
          end
        end
      end

      shared_examples :updater_no_expires do
        it 'causes the value not to expire after the given number of seconds' do
          updater.call(expires: expires)
          keys.zip(values).each do |key, value|
            expect(store.load(key)).to eq value
            expect(store[key]).to eq value
          end
          advance min_ttl + t_res
          keys.zip(values).each do |key, value|
            expect(store.load(key)).to eq value
            expect(store[key]).to eq value
          end
        end
      end

      context "with a zero :expires parameter" do
        let(:expires) { 0 }
        include_examples :updater_no_expires
      end

      context "with a false :expires parameter" do
        let(:expires) { false }
        include_examples :updater_no_expires
      end
    end

    # All methods that are used to for loading, and that include an expire parameter
    shared_examples :loader_expiry do
      it "does not affect expiry if the value is not present" do
        expect(loader.call(expires: min_ttl)).to be_absent
        expect(loader.call).to be_absent
      end

      shared_examples :loader_expires do
        context 'when passed a positive numeric :expires parameter' do
          it 'changes the expiry of the value(s) to the given number of seconds' do
            expect(loader.call).to be_present
            expect(loader.call(expires: min_ttl + 2 * t_res)).to be_present
            advance min_ttl + t_res
            expect(loader.call).to be_present
            advance 2 * t_res
            expect(loader.call).to be_absent
          end
        end
      end

      context 'with previously stored expiring value(s)' do
        before do
          keys.zip(values).each do |key, value|
            store.store(key, value, expires: min_ttl)
          end
        end
        include_examples :loader_expires

        shared_examples :loader_no_expires do
          it "changes the expiry of the value(s) so that they don't expire" do
            expect(loader.call(expires: expires)).to be_present
            advance min_ttl + t_res
            expect(loader.call).to be_present
          end
        end

        context "when passed a zero :expires parameter" do
          let(:expires) { 0 }
          include_examples :loader_no_expires
        end

        context "when passed false :expires parameter" do
          let(:expires) { false }
          include_examples :loader_no_expires
        end

        shared_examples :loader_no_effect do
          it 'does not affect the expiry time' do
            expect(loader_no_effect.call).to be_present
            advance min_ttl + t_res
            expect(loader.call).to be_absent
          end
        end

        context 'when passed a nil :expires parameter' do
          let(:loader_no_effect) { lambda { loader.call(expires: nil) } }
          include_examples :loader_no_effect
        end

        context 'when not passed an :expires parameter' do
          let(:loader_no_effect) { loader }
          include_examples :loader_no_effect
        end
      end

      context "with previously stored not expiring value(s)" do
        before do
          keys.zip(values).each do |key, value|
            store.store(key, value, expires: false)
          end
        end
        include_examples :loader_expires
      end
    end

    describe '#store' do
      let(:keys) { ['key1'] }
      let(:values) { ['value1'] }
      let(:updater) do
        lambda do |**options|
          expect(store.store(keys[0], values[0], options)).to eq values[0]
        end
      end

      include_examples :updater_expiry
    end

    describe '#load' do
      let(:keys) { ['key1'] }
      let(:values) { ['value1'] }
      let(:loader) do
        lambda { |**options| store.load('key1', options) }
      end
      let(:be_present) { eq 'value1' }
      let(:be_absent) { be_nil }

      include_examples :loader_expiry
    end

    describe '#key?' do
      let(:keys) { ['key1'] }
      let(:values) { ['value1'] }
      let(:loader) do
        lambda { |**options| store.key?('key1', options) }
      end
      let(:be_present) { be true }
      let(:be_absent) { be false }

      include_examples :loader_expiry
    end

    describe '#fetch' do
      let(:keys) { ['key1'] }
      let(:values) { ['value1'] }
      let(:be_present) { eq 'value1' }

      context "with default given as second parameter" do
        let(:loader) do
          lambda { |**options| store.fetch('key1', 'missing', options) }
        end
        let(:be_absent) { eq 'missing' }

        include_examples :loader_expiry
      end

      context "with default given as a block" do
        let(:loader) do
          lambda { |**options| store.fetch('key1', options) { 'missing' } }
        end
        let(:be_absent) { eq 'missing' }

        include_examples :loader_expiry
      end

      context "with nil default given" do
        let(:loader) do
          lambda { |**options| store.fetch('key1', nil, options) }
        end
        let(:be_absent) { be_nil }

        include_examples :loader_expiry
      end
    end

    describe '#delete' do
      context 'with an already expired value' do
        before do
          store.store('key2', 'val2', expires: min_ttl)
          expect(store['key2']).to eq 'val2'
          advance min_ttl + t_res
        end

        it 'does not return the expired value' do
          expect(store.delete('key2')).to be_nil
        end
      end
    end

    describe '#expires' do
      it "returns a store with access to the same items" do
        store.store('persistent_key', 'persistent_value', expires: false)
        store_expires = store.expires(min_ttl)
        expect(store_expires['persistent_key']).to eq 'persistent_value'
      end

      it "returns a store with default expiry set" do
        store_expires = store.expires(min_ttl)
        expect(store_expires.store('key1', 'val1')).to eq 'val1'
        expect(store_expires['key1']).to eq 'val1'
        advance min_ttl + t_res
        expect(store['key1']).to be_nil
      end
    end

    describe '#merge!' do
      let(:keys) { ['key1', 'key2'] }
      let(:values) { ['value1', 'value2'] }
      let(:updater) do
        lambda do |**options|
          expect(store.merge!(keys.zip(values), options)).to eq store
        end
      end

      include_examples :updater_expiry
    end

    describe '#values_at' do
      let(:keys) { ['key1', 'key2'] }
      let(:values) { ['value1', 'value2'] }
      let(:loader) do
        lambda { |**options| store.values_at('key1', 'key2', **options) }
      end
      let(:be_present) { eq ['value1', 'value2'] }
      let(:be_absent) { eq [nil, nil] }

      include_examples :loader_expiry
    end

    describe '#fetch_values' do
      let(:keys) { ['key1', 'key2'] }
      let(:values) { ['value1', 'value2'] }
      let(:be_present) { eq ['value1', 'value2'] }

      context 'with default values given via a block' do
        let(:loader) do
          lambda do |**options|
            store.fetch_values('key1', 'key2', **options) { |k| "#{k} missing" }
          end
        end
        let(:be_absent) { eq ['key1 missing', 'key2 missing'] }

        include_examples :loader_expiry
      end

      context 'without default values given' do
        let(:loader) do
          lambda do |**options|
            store.fetch_values('key1', 'key2', **options)
          end
        end
        let(:be_absent) { eq [nil, nil] }

        include_examples :loader_expiry
      end
    end

    describe '#slice' do
      let(:keys) { ['key1', 'key2'] }
      let(:values) { ['value1', 'value2'] }
      let(:loader) do
        lambda { |**options| store.slice('key1', 'key2', **options) }
      end
      let(:be_present) { contain_exactly(['key1', 'value1'], ['key2', 'value2']) }
      let(:be_absent) { be_empty }

      include_examples :loader_expiry
    end
  end
end
