shared_examples :concurrent_create do
  # Each thread attempts to create
  def create_thread(name)
    Thread.new do
      s = new_store
      begin
        (0...1000).map do |i|
          s.create(i.to_s, name, expires: false).tap do
            Thread.pass if rand(100) >= 99
          end
        end
      ensure
        s.close
      end
    end
  end

  it 'have atomic create across multiple threads', isolate: true do
    names = %w{a b c}

    # Spawn threads and then group results (lists of true/false values) by
    # store index (0...1000)
    results = names
      .map { |name| create_thread(name) }
      .map(&:value)
      .transpose.each_with_index
      .map { |created_values, i| [i.to_s, created_values] }
      .to_h

    # Just a quick sanity check
    expect(results.length).to eq 1000

    # Ensure that for each index, one and only one created value is true
    expect(results.map { |_, created_values| created_values.inject(:^) }).to all(be true)

    # Check that the when a call to create returned true, that the store
    # contains the correct value as a result
    expect(store.slice(*results.keys).to_h).to eq(results.map do |i, values|
      [i, names[values.index(true)]]
    end.to_h)
  end
end
