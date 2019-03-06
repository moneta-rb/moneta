describe 'adapter_lruhash', adapter: :LRUHash do
  moneta_build do
    Moneta::Adapters::LRUHash.new
  end

  moneta_specs ADAPTER_SPECS.with_each_key.without_persist.returnsame

  it 'deletes oldest' do
    store = Moneta::Adapters::LRUHash.new(max_size: 10)
    store[0]  = 'y'
    (1..1000).each do |i|
      store[i] = 'x'
      store[0].should == 'y'
      store.instance_variable_get(:@entry).size.should == [10, i+1].min
      (0...[9, i-1].min).each do |j|
        store.instance_variable_get(:@entry)[i-j].should_not be_nil
      end
      store.key?(i-9).should be false if i > 9
    end
  end

  it 'adds a value that is the same as max_size' do
    store = Moneta::Adapters::LRUHash.new(max_size: 21)
    store[:a_key] = 'This is 21 bytes long'
    store[:a_key].should eq('This is 21 bytes long')
  end

  it 'does not add a value that is larger than max_size' do
    store = Moneta::Adapters::LRUHash.new(max_size: 20)
    store[:too_long] = 'This is 21 bytes long'
    store[:too_long].should be_nil
  end

  it 'removes an existing key that is replaced by an item that is larger than max_size' do
    store = Moneta::Adapters::LRUHash.new(max_size: 20)
    store[:a_key] = 'This will fit'
    store[:a_key] = 'This is 21 bytes long'
    store[:a_key].should be_nil
  end

  it 'does not add a value that is larger than max_size, when max_value is explicitly missing' do
    store = Moneta::Adapters::LRUHash.new(max_size: 20, max_value: nil)
    store[:too_long] = 'This is 21 bytes long'
    store[:too_long].should be_nil
  end

  it 'does not add a value that is larger than max_size, even if max_value is larger than max_size' do
    store = Moneta::Adapters::LRUHash.new(max_size: 20, max_value: 25)
    store[:too_long] = 'This is 21 bytes long'
    store[:too_long].should be_nil
  end

  it 'adds a value that is as large as the default max_size when max_size is missing' do
    store = Moneta::Adapters::LRUHash.new
    large_item = 'Really big'
    allow(large_item).to receive(:bytesize).and_return(Moneta::Adapters::LRUHash::DEFAULT_MAX_SIZE)
    store[:really_big] = large_item
    store[:really_big].should eq(large_item)
  end

  it 'does not add values that are larger than the default max_size when max_size is missing' do
    store = Moneta::Adapters::LRUHash.new
    large_item = 'Really big'
    allow(large_item).to receive(:bytesize).and_return(Moneta::Adapters::LRUHash::DEFAULT_MAX_SIZE + 1)
    store[:really_big] = large_item
    store[:really_big].should be_nil
  end

  it 'adds values that are larger than the default max_size when max_size is nil' do
    store = Moneta::Adapters::LRUHash.new(max_size: nil)
    large_item = 'Really big'
    allow(large_item).to receive(:bytesize).and_return(Moneta::Adapters::LRUHash::DEFAULT_MAX_SIZE + 1)
    store[:really_big] = large_item
    store[:really_big].should eq(large_item)
  end

  it 'adds an individual value that is equal to max_value' do
    store = Moneta::Adapters::LRUHash.new(max_value: 13)
    store[:a_key] = '13 bytes long'
    store[:a_key].should eq('13 bytes long')
  end

  it 'does not add a value that is larger than max_value' do
    store = Moneta::Adapters::LRUHash.new(max_value: 20)
    store[:too_long] = 'This is 21 bytes long'
    store[:too_long].should be_nil
  end

  it 'removes keys that are replaced by values larger than max_value' do
    store = Moneta::Adapters::LRUHash.new(max_value: 20)
    store[:too_long] = 'This will fit'
    store[:too_long] = 'This is 21 bytes long'
    store[:too_long].should be_nil
  end

  it 'only allows the default number of items when max_count is missing' do
    stub_const('Moneta::Adapters::LRUHash::DEFAULT_MAX_COUNT', 5)
    store = Moneta::Adapters::LRUHash.new(max_value: nil, max_size: nil)
    (1..6).each { |n| store[n] = n }
    store.key?(1).should be false
    store[1].should be_nil
    store[2].should eq(2)
    store[6].should eq(6)
  end

  it 'adds more values than DEFAULT_MAX_COUNT allows when max_count is nil' do
    stub_const('Moneta::Adapters::LRUHash::DEFAULT_MAX_COUNT', 5)
    store = Moneta::Adapters::LRUHash.new(max_count: nil, max_value: nil, max_size: nil)
    (1..6).each { |n| store[n] = n }
    store[1].should eq(1)
    store[2].should eq(2)
    store[6].should eq(6)
  end
end
